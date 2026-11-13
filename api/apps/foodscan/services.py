"""
Services du scan : analyser un repas, recevoir les avis, en tirer des règles.

Boucle complète (V1, sans modèle entraîné) :

    photo + pays ─► prompt (pays, fiches locales, confusions validées) ─► IA
                                                                         │
    règles actives ◄── consensus / validateur ◄── avis des utilisateurs ◄┘

L'IA donne le plat, les ingrédients et leurs grammes. Elle ne donne aucun
nutriment : `meals` rapproche les ingrédients de `nutrition.Food`.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from typing import Any, Literal

from django.conf import settings
from django.db import transaction
from django.utils import timezone
from pydantic import ValidationError

from apps.foodscan import consensus, prompting, selectors
from apps.foodscan.client import (
    Completion,
    OpenRouterClient,
    ProviderError,
    ProviderTimeoutError,
    VisionClient,
)
from apps.foodscan.images import UnsupportedImageError, prepare_image, to_data_url
from apps.foodscan.models import ConfusionRule, ScanReview
from apps.foodscan.regions import normalize_country
from apps.foodscan.schemas import ConfusionHint, DishHint, ScanOutput, clean_label, normalize_key

# Mêmes codes que `Analysis.failure_reason` dans le contrat d'API.
FailureReason = Literal["blurry", "no_food", "unsupported", "provider_error", "timeout"]


@dataclass(slots=True)
class ScanResult:
    """Tout ce que `meals` doit enregistrer dans `Analysis`."""

    succeeded: bool
    failure_reason: FailureReason | None
    output: ScanOutput | None
    low_confidence: bool
    model: str
    prompt_version: str
    tokens_in: int = 0
    tokens_out: int = 0
    cost_usd_micros: int | None = None
    raw_response: dict[str, Any] = field(default_factory=dict)
    # Ce qui a orienté l'IA : de quoi expliquer un résultat dans l'admin.
    context: dict[str, Any] = field(default_factory=dict)

    @property
    def counted_in_quota(self) -> bool:
        """Une photo floue ou sans aliment ne compte pas (02-saisie-repas.md)."""
        return self.succeeded


def _setting(name: str, default: Any) -> Any:
    return getattr(settings, name, default)


def default_client() -> VisionClient:
    return OpenRouterClient(
        api_key=settings.OPENROUTER_API_KEY,
        base_url=_setting("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1"),
        timeout_s=float(_setting("FOODSCAN_TIMEOUT_S", 30)),
    )


def build_context(
    *, country: str | None, use_knowledge: bool = True
) -> tuple[list[DishHint], list[ConfusionHint]]:
    if not use_knowledge:
        return [], []
    return (
        selectors.dish_hints_for(country=country, limit=int(_setting("FOODSCAN_MAX_DISH_HINTS", 40))),
        selectors.confusion_hints_for(country=country, limit=int(_setting("FOODSCAN_MAX_RULES", 20))),
    )


def parse_output(content: str) -> ScanOutput:
    """Extrait et valide le JSON, même entouré de ```json … ```."""
    text = content.strip()
    fenced = re.search(r"```(?:json)?\s*(\{.*\})\s*```", text, re.DOTALL)
    if fenced:
        text = fenced.group(1)
    elif not text.startswith("{"):
        start, end = text.find("{"), text.rfind("}")
        if start == -1 or end <= start:
            raise ProviderError("Aucun JSON dans la réponse de l'IA.")
        text = text[start : end + 1]
    try:
        return ScanOutput.model_validate(json.loads(text))
    except (json.JSONDecodeError, ValidationError) as exc:
        raise ProviderError("Réponse de l'IA hors format.") from exc


def _run(
    *,
    messages: list[dict[str, Any]],
    client: VisionClient | None,
    context: dict[str, Any],
    check_image_quality: bool,
) -> ScanResult:
    model = str(_setting("FOODSCAN_VISION_MODEL", "") or settings.OPENROUTER_VISION_MODEL)
    base = {"model": model, "prompt_version": prompting.PROMPT_VERSION, "context": context}

    try:
        completion: Completion = (client or default_client()).complete(messages=messages, model=model)
    except ProviderTimeoutError:
        return ScanResult(succeeded=False, failure_reason="timeout", output=None, low_confidence=False, **base)
    except ProviderError as exc:
        base["context"] = {**context, "error": str(exc)}
        return ScanResult(succeeded=False, failure_reason="provider_error", output=None, low_confidence=False, **base)

    usage = {
        "model": completion.model or model,
        "prompt_version": prompting.PROMPT_VERSION,
        "context": context,
        "tokens_in": completion.tokens_in,
        "tokens_out": completion.tokens_out,
        "cost_usd_micros": completion.cost_usd_micros,
        "raw_response": completion.raw,
    }
    try:
        output = parse_output(completion.content)
    except ProviderError:
        return ScanResult(succeeded=False, failure_reason="provider_error", output=None, low_confidence=False, **usage)

    failure: FailureReason | None = None
    if not output.contains_food:
        failure = "no_food"
    elif check_image_quality and output.image_quality == "blurry":
        failure = "blurry"
    elif not output.dish_label and not output.items:
        failure = "no_food"

    threshold = float(_setting("FOODSCAN_LOW_CONFIDENCE", 0.6))
    return ScanResult(
        succeeded=failure is None,
        failure_reason=failure,
        output=output,
        low_confidence=failure is None and output.confidence < threshold,
        **usage,
    )


def _context_summary(country: str | None, dishes: list[DishHint], rules: list[ConfusionHint]) -> dict[str, Any]:
    return {
        "country": country,
        "dish_hints": [d.key for d in dishes],
        "rules": [f"{r.predicted_key}>{r.correct_key}" for r in rules],
    }


def scan_photo(
    *,
    image_bytes: bytes,
    country: str | None,
    locale: str | None,
    client: VisionClient | None = None,
    use_knowledge: bool = True,
) -> ScanResult:
    """Analyse une photo de repas. Ne lève pas : un échec est un `ScanResult` en échec."""
    code = normalize_country(country)
    dishes, rules = build_context(country=code, use_knowledge=use_knowledge)
    context = _context_summary(code, dishes, rules)
    try:
        jpeg = prepare_image(image_bytes)
    except UnsupportedImageError as exc:
        return ScanResult(
            succeeded=False,
            failure_reason="unsupported",
            output=None,
            low_confidence=False,
            model="",
            prompt_version=prompting.PROMPT_VERSION,
            context={**context, "error": str(exc)},
        )
    instructions = prompting.build_instructions(country=code, locale=locale, dishes=dishes, rules=rules)
    messages = prompting.build_photo_messages(instructions=instructions, image_data_url=to_data_url(jpeg))
    return _run(messages=messages, client=client, context=context, check_image_quality=True)


def scan_text(
    *,
    text: str,
    country: str | None,
    locale: str | None,
    client: VisionClient | None = None,
    use_knowledge: bool = True,
) -> ScanResult:
    """Analyse une description de repas (saisie libre ou vocale transcrite)."""
    code = normalize_country(country)
    dishes, rules = build_context(country=code, use_knowledge=use_knowledge)
    instructions = prompting.build_instructions(country=code, locale=locale, dishes=dishes, rules=rules)
    messages = prompting.build_text_messages(instructions=instructions, text=text)
    return _run(
        messages=messages, client=client, context=_context_summary(code, dishes, rules), check_image_quality=False
    )


# ──────────────────────────────────────────────────────────────────────────
# Avis et validation
# ──────────────────────────────────────────────────────────────────────────


def _policy() -> consensus.ConsensusPolicy:
    return consensus.ConsensusPolicy(
        min_distinct_users=int(_setting("FOODSCAN_CONSENSUS_MIN_USERS", 3)),
        min_agreement=float(_setting("FOODSCAN_CONSENSUS_MIN_AGREEMENT", 0.6)),
    )


@transaction.atomic
def submit_review(
    *,
    user: Any,
    country: str | None,
    predicted_label: str | None,
    correct_label: str,
    analysis_id: Any = None,
    predicted_key: str | None = None,
    correct_key: str | None = None,
    photo_key: str = "",
) -> ScanReview:
    """
    Enregistre la correction d'un utilisateur, puis recalcule les règles du pays.

    Appelé par `meals` quand l'utilisateur corrige le plat d'une analyse. Un
    second avis sur la même analyse remplace le premier.
    """
    code = normalize_country(country) or ""
    correct = clean_label(correct_label)
    if not correct:
        raise ValueError("Le plat corrigé est obligatoire.")
    predicted = clean_label(predicted_label)
    values = {
        "country": code,
        "predicted_label": predicted,
        "predicted_key": normalize_key(predicted_key or predicted),
        "correct_label": correct,
        "correct_key": normalize_key(correct_key or correct),
        "photo_key": photo_key,
        "status": ScanReview.Status.PROPOSED,
        "decided_by": None,
        "decided_at": None,
    }
    if analysis_id is not None:
        review, _ = ScanReview.objects.update_or_create(user=user, analysis_id=analysis_id, defaults=values)
    else:
        review = ScanReview.objects.create(user=user, **values)

    if code and review.is_correction:
        rebuild_confusion_rules(country=code)
        review.refresh_from_db()
    return review


@transaction.atomic
def moderate_review(*, review: ScanReview, moderator: Any, approve: bool, hint: str = "") -> ScanReview:
    """
    Décision d'un validateur de confiance. Une approbation crée la règle tout
    de suite, sans attendre le consensus ; un rejet retire l'avis du calcul.
    """
    review.status = ScanReview.Status.VALIDATED if approve else ScanReview.Status.REJECTED
    review.decided_by = moderator
    review.decided_at = timezone.now()
    review.save(update_fields=["status", "decided_by", "decided_at"])

    if approve and review.country and review.is_correction:
        rule, created = ConfusionRule.objects.get_or_create(
            country=review.country,
            predicted_key=review.predicted_key,
            correct_key=review.correct_key,
            defaults={
                "predicted_label": review.predicted_label,
                "correct_label": review.correct_label,
                "origin": ConfusionRule.Origin.MODERATOR,
                "support": 1,
                "agreement": 1.0,
                "hint": hint.strip(),
            },
        )
        if not created:
            rule.origin = ConfusionRule.Origin.MODERATOR
            rule.status = ConfusionRule.Status.ACTIVE
            if hint.strip():
                rule.hint = hint.strip()
            rule.save(update_fields=["origin", "status", "hint", "updated_at"])

    if review.country:
        rebuild_confusion_rules(country=review.country)
    return review


@transaction.atomic
def rebuild_confusion_rules(*, country: str) -> list[consensus.RuleCandidate]:
    """
    Recalcule les règles d'un pays à partir des avis non rejetés. Idempotent.

    - Consensus atteint : la règle est créée ou réactivée, et ses avis passent
      en `validated`.
    - Consensus perdu : une règle de consensus est désactivée. Une règle posée
      par un validateur reste active : seul un validateur la retire.
    - Une règle désactivée à la main (statut `disabled`, origine validateur)
      n'est jamais réactivée par le calcul.
    """
    code = normalize_country(country)
    if not code:
        return []

    reviews = list(
        ScanReview.objects.filter(country=code)
        .exclude(status=ScanReview.Status.REJECTED)
        .exclude(user__isnull=True)
        .values("id", "user_id", "predicted_key", "predicted_label", "correct_key", "correct_label")
    )
    votes = [
        consensus.Vote(
            user_id=str(r["user_id"]),
            country=code,
            predicted_key=r["predicted_key"],
            correct_key=r["correct_key"],
            predicted_label=r["predicted_label"],
            correct_label=r["correct_label"],
        )
        for r in reviews
    ]
    candidates = consensus.evaluate(votes, _policy())
    existing = {(r.predicted_key, r.correct_key): r for r in ConfusionRule.objects.filter(country=code)}

    for cand in candidates:
        rule = existing.get((cand.predicted_key, cand.correct_key))
        if cand.accepted:
            if rule is None:
                ConfusionRule.objects.create(
                    country=code,
                    predicted_key=cand.predicted_key,
                    predicted_label=cand.predicted_label,
                    correct_key=cand.correct_key,
                    correct_label=cand.correct_label,
                    support=cand.support,
                    agreement=cand.agreement,
                )
            else:
                rule.support, rule.agreement = cand.support, cand.agreement
                manually_disabled = (
                    rule.origin == ConfusionRule.Origin.MODERATOR and rule.status == ConfusionRule.Status.DISABLED
                )
                if not manually_disabled:
                    rule.status = ConfusionRule.Status.ACTIVE
                rule.save(update_fields=["support", "agreement", "status", "updated_at"])
            ScanReview.objects.filter(
                country=code,
                predicted_key=cand.predicted_key,
                correct_key=cand.correct_key,
                status=ScanReview.Status.PROPOSED,
            ).update(status=ScanReview.Status.VALIDATED, decided_at=timezone.now())
        elif rule is not None:
            rule.support, rule.agreement = cand.support, cand.agreement
            if rule.origin == ConfusionRule.Origin.CONSENSUS:
                rule.status = ConfusionRule.Status.DISABLED
            rule.save(update_fields=["support", "agreement", "status", "updated_at"])

    # Règles de consensus dont plus aucun avis ne subsiste.
    remaining = {(c.predicted_key, c.correct_key) for c in candidates}
    for pair, rule in existing.items():
        if pair not in remaining and rule.origin == ConfusionRule.Origin.CONSENSUS:
            rule.status = ConfusionRule.Status.DISABLED
            rule.support = 0
            rule.save(update_fields=["status", "support", "updated_at"])
    return candidates
