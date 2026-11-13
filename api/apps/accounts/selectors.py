"""Lectures du compte : `Me`, documents à réaccepter, état des consentements, villes, sessions."""

from __future__ import annotations

from typing import Any

from django.db.models import Q, QuerySet
from django.db.models.fields.json import KT

from apps.accounts.models import (
    NON_WITHDRAWABLE_CONSENTS,
    City,
    Consent,
    ConsentKind,
    LegalDocument,
    LegalKind,
    Session,
    User,
)
from apps.billing.models import QuotaRule
from apps.billing.services import entitlement_for
from apps.core import settings_store
from apps.core.localtime import local_today
from apps.nutrition.calculations import age_on
from apps.nutrition.selectors import target_on


def user_for_me(user_id: Any) -> User:
    return User.objects.select_related("profile", "profile__city", "profile__avatar").get(pk=user_id)


def me_context(user_id: Any) -> dict[str, Any]:
    """Tout ce qu'il faut pour `Me` : utilisateur, âge, objectifs du jour, droits, documents à réaccepter."""
    user = user_for_me(user_id)
    today = local_today(user)
    return {
        "user": user,
        "age": age_on(user.profile.birth_date, today),
        "target": target_on(user=user, day=today),
        "entitlement": entitlement_for(user),
        "pending": pending_documents(user),
    }


def app_config() -> dict[str, Any]:
    """Configuration publique (`GET /app/config`), entièrement issue des réglages et des documents publiés."""
    app = settings_store.get("app")
    quotas = {
        f"{rule.plan_tier}.{rule.feature}": {"limit": rule.limit, "period": rule.period}
        for rule in QuotaRule.objects.order_by("plan_tier", "feature")
    }
    return {
        "min_version": {"android": app["min_version_android"], "ios": app["min_version_ios"]},
        "latest_version": {
            "android": app.get("latest_version_android", app["min_version_android"]),
            "ios": app.get("latest_version_ios", app["min_version_ios"]),
        },
        "locales": list(app["active_locales"]),
        "features": dict(app["features"]),
        "web_checkout_countries": list(app.get("web_checkout_countries", [])),
        "min_age": int(app["min_age"]),
        "trial_days": {
            "default": int(settings_store.get("trial.default_days")),
            "with_invite": int(settings_store.get("trial.invite_days")),
        },
        "quotas_display": quotas,
        "legal_versions": {kind: doc.version for kind, doc in latest_published_documents().items()},
        "support_email": app.get("support_email", "support@omeo.app"),
        "store_urls": app.get("store_urls", {}),
    }


def latest_published_documents() -> dict[str, LegalDocument]:
    latest: dict[str, LegalDocument] = {}
    for document in LegalDocument.objects.filter(published_at__isnull=False).order_by("kind", "-version"):
        latest.setdefault(document.kind, document)
    return latest


def latest_consents(user: User) -> dict[str, Consent]:
    """Dernier enregistrement par `kind` (table en ajout seul)."""
    rows = (
        Consent.objects.filter(user=user)
        .select_related("document")
        .order_by("kind", "-created_at")
        .distinct("kind")
    )
    return {row.kind: row for row in rows}


def pending_documents(user: User) -> list[LegalDocument]:
    """CGU et confidentialité publiées dans une version à réaccepter, plus récente que celle acceptée."""
    documents = latest_published_documents()
    consents = latest_consents(user)
    pending: list[LegalDocument] = []
    for kind in (LegalKind.TERMS, LegalKind.PRIVACY):
        document = documents.get(kind)
        if document is None or not document.requires_reaccept:
            continue
        consent = consents.get(kind)
        accepted_version = consent.document.version if consent and consent.granted and consent.document else 0
        if accepted_version < document.version:
            pending.append(document)
    return pending


def consent_states(user: User) -> list[dict[str, Any]]:
    consents = latest_consents(user)
    states = []
    for kind in ConsentKind.values:
        consent = consents.get(kind)
        if consent is None:
            continue
        states.append(
            {
                "kind": kind,
                "granted": consent.granted,
                "version": consent.document.version if consent.document else None,
                "updated_at": consent.created_at,
                "withdrawable": kind not in NON_WITHDRAWABLE_CONSENTS,
            }
        )
    return states


def search_cities(*, q: str | None, country: str | None, limit: int = 20) -> QuerySet[City]:
    queryset = City.objects.annotate(name_fr=KT("name__fr"), name_en=KT("name__en"))
    if country:
        queryset = queryset.filter(country=country.upper())
    if q:
        term = q.strip()
        queryset = queryset.filter(Q(name_fr__unaccent__icontains=term) | Q(name_en__unaccent__icontains=term))
    else:
        queryset = queryset.filter(is_suggested=True)
    return queryset.order_by("country", "name_fr")[:limit]


def active_sessions(user: User) -> QuerySet[Session]:
    return Session.objects.filter(user=user, revoked_at__isnull=True).order_by("-last_used_at")
