"""Services : scan avec un faux fournisseur IA, avis et consensus en base."""

from __future__ import annotations

import io
import json
from typing import Any

from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from PIL import Image

from apps.foodscan import services
from apps.foodscan.client import Completion, ProviderError, ProviderTimeoutError
from apps.foodscan.models import ConfusionRule, DishKnowledge, ScanReview


def photo() -> bytes:
    buffer = io.BytesIO()
    Image.new("RGB", (64, 64), "green").save(buffer, format="JPEG")
    return buffer.getvalue()


class FakeClient:
    def __init__(self, content: str | None = None, error: Exception | None = None) -> None:
        self.content, self.error = content, error
        self.messages: list[dict[str, Any]] = []

    def complete(self, *, messages: list[dict[str, Any]], model: str) -> Completion:
        self.messages = messages
        if self.error:
            raise self.error
        return Completion(content=self.content or "", model="vision-x", tokens_in=10, tokens_out=5,
                          cost_usd_micros=900, raw={"ok": True})

    @property
    def system_prompt(self) -> str:
        return self.messages[0]["content"]


def answer(**overrides: Any) -> str:
    data = {"contains_food": True, "image_quality": "ok", "dish_label": "Ndolé", "dish_key": "ndole",
            "confidence": 0.9, "items": [{"label": "Feuilles de ndolé", "grams": 150, "confidence": 0.8}]}
    data.update(overrides)
    return json.dumps(data)


@override_settings(FOODSCAN_VISION_MODEL="vision-x", FOODSCAN_LOW_CONFIDENCE=0.6)
class ScanTests(TestCase):
    def test_success(self) -> None:
        result = services.scan_photo(image_bytes=photo(), country="CM", locale="fr", client=FakeClient(answer()))
        self.assertTrue(result.succeeded)
        self.assertTrue(result.counted_in_quota)
        self.assertFalse(result.low_confidence)
        self.assertEqual(result.output.dish_key, "ndole")
        self.assertEqual(result.cost_usd_micros, 900)
        self.assertEqual(result.prompt_version, "foodscan-v1.0")

    def test_low_confidence(self) -> None:
        result = services.scan_photo(image_bytes=photo(), country="CM", locale="fr",
                                     client=FakeClient(answer(confidence=0.3)))
        self.assertTrue(result.succeeded)
        self.assertTrue(result.low_confidence)

    def test_no_food_and_blurry_are_not_counted(self) -> None:
        for content, reason in [(answer(contains_food=False, dish_label=None), "no_food"),
                                (answer(image_quality="blurry"), "blurry")]:
            result = services.scan_photo(image_bytes=photo(), country="CM", locale="fr", client=FakeClient(content))
            self.assertEqual(result.failure_reason, reason)
            self.assertFalse(result.counted_in_quota)

    def test_fenced_json_is_accepted(self) -> None:
        result = services.scan_photo(image_bytes=photo(), country="CM", locale="fr",
                                     client=FakeClient(f"Voici :\n```json\n{answer()}\n```"))
        self.assertTrue(result.succeeded)

    def test_invalid_output_is_a_provider_error(self) -> None:
        for content in ["pas de json", answer(confidence=7)]:
            result = services.scan_photo(image_bytes=photo(), country="CM", locale="fr", client=FakeClient(content))
            self.assertEqual(result.failure_reason, "provider_error")
            self.assertEqual(result.tokens_in, 10)  # le coût reste tracé

    def test_provider_failures(self) -> None:
        for error, reason in [(ProviderTimeoutError("x"), "timeout"), (ProviderError("x"), "provider_error")]:
            result = services.scan_photo(image_bytes=photo(), country="CM", locale="fr", client=FakeClient(error=error))
            self.assertEqual(result.failure_reason, reason)

    def test_unsupported_image_never_calls_the_provider(self) -> None:
        client = FakeClient(answer())
        result = services.scan_photo(image_bytes=b"xx", country="CM", locale="fr", client=client)
        self.assertEqual(result.failure_reason, "unsupported")
        self.assertEqual(client.messages, [])

    def test_prompt_gets_country_knowledge_then_region(self) -> None:
        DishKnowledge.objects.create(key="ndole", name="Ndolé", country="CM", region="central_africa",
                                     visual_description="Feuilles vertes hachées, arachide.")
        DishKnowledge.objects.create(key="ndole", name="Ndolé (régional)", scope="region",
                                     region="central_africa", visual_description="Doublon régional.")
        DishKnowledge.objects.create(key="saka_saka", name="Saka-saka", scope="region",
                                     region="central_africa", visual_description="Feuilles de manioc pilées.")
        DishKnowledge.objects.create(key="garba", name="Garba", country="CI", region="west_africa",
                                     visual_description="Attiéké et thon frit.")
        client = FakeClient(answer())
        result = services.scan_photo(image_bytes=photo(), country="CM", locale="fr", client=client)
        self.assertEqual(result.context["dish_hints"], ["ndole", "saka_saka"])
        self.assertIn("Feuilles vertes hachées", client.system_prompt)
        self.assertNotIn("Doublon régional", client.system_prompt)
        self.assertNotIn("Garba", client.system_prompt)

    def test_use_knowledge_false_sends_a_bare_prompt(self) -> None:
        DishKnowledge.objects.create(key="ndole", name="Ndolé", country="CM", region="central_africa",
                                     visual_description="Feuilles.")
        client = FakeClient(answer())
        services.scan_photo(image_bytes=photo(), country="CM", locale="fr", client=client, use_knowledge=False)
        self.assertNotIn("FICHES", client.system_prompt)

    def test_text_scan(self) -> None:
        client = FakeClient(answer(image_quality="blurry"))
        result = services.scan_text(text="Une assiette de ndolé", country="CM", locale="fr", client=client)
        self.assertTrue(result.succeeded)  # pas de notion de flou sans photo
        self.assertEqual(client.messages[1]["content"], "Description du repas : « Une assiette de ndolé »")


@override_settings(FOODSCAN_CONSENSUS_MIN_USERS=3, FOODSCAN_CONSENSUS_MIN_AGREEMENT=0.6)
class ReviewTests(TestCase):
    def setUp(self) -> None:
        User = get_user_model()
        self.users = [User.objects.create(username=f"u{i}") for i in range(6)]
        self.moderator = User.objects.create(username="modo", is_staff=True)

    def correct(self, user: Any, correct: str = "Eru", predicted: str = "Sauce gombo",
                analysis_id: Any = None) -> ScanReview:
        return services.submit_review(user=user, country="cm", predicted_label=predicted,
                                      correct_label=correct, analysis_id=analysis_id)

    def test_rule_appears_at_consensus_and_reaches_the_prompt(self) -> None:
        self.correct(self.users[0])
        self.correct(self.users[1])
        self.assertFalse(ConfusionRule.objects.exists())

        review = self.correct(self.users[2])
        rule = ConfusionRule.objects.get()
        self.assertEqual((rule.country, rule.predicted_key, rule.correct_key, rule.support),
                         ("CM", "sauce_gombo", "eru", 3))
        self.assertEqual(review.status, ScanReview.Status.VALIDATED)
        self.assertEqual(ScanReview.objects.filter(status="validated").count(), 3)

        client = FakeClient(answer())
        services.scan_photo(image_bytes=photo(), country="CM", locale="fr", client=client)
        self.assertIn("sauce_gombo>eru", client.system_prompt)
        # Règle propre à son pays : rien au Gabon.
        client_ga = FakeClient(answer())
        services.scan_photo(image_bytes=photo(), country="GA", locale="fr", client=client_ga)
        self.assertNotIn("sauce_gombo>eru", client_ga.system_prompt)

    def test_same_user_cannot_force_a_rule(self) -> None:
        for _ in range(5):
            self.correct(self.users[0])
        self.assertFalse(ConfusionRule.objects.exists())

    def test_second_review_on_same_analysis_replaces_the_first(self) -> None:
        import uuid

        analysis = uuid.uuid4()
        self.correct(self.users[0], correct="Ndolé", analysis_id=analysis)
        self.correct(self.users[0], correct="Eru", analysis_id=analysis)
        self.assertEqual(ScanReview.objects.get().correct_key, "eru")

    def test_moderator_approval_creates_the_rule_immediately(self) -> None:
        review = self.correct(self.users[0])
        services.moderate_review(review=review, moderator=self.moderator, approve=True, hint="L'eru est plus fin.")
        rule = ConfusionRule.objects.get()
        self.assertEqual((rule.origin, rule.status, rule.hint), ("moderator", "active", "L'eru est plus fin."))

    def test_rejected_reviews_leave_the_consensus(self) -> None:
        reviews = [self.correct(u) for u in self.users[:3]]
        self.assertEqual(ConfusionRule.objects.get().status, "active")
        services.moderate_review(review=reviews[0], moderator=self.moderator, approve=False)
        self.assertEqual(ConfusionRule.objects.get().status, "disabled")

    def test_disagreement_creates_no_rule(self) -> None:
        for u in self.users[:3]:
            self.correct(u, correct="Eru")
        self.assertEqual(ConfusionRule.objects.get().status, "active")
        for u in self.users[3:6]:
            self.correct(u, correct="Ndolé")
        self.assertFalse(ConfusionRule.objects.filter(status="active").exists())  # 3 contre 3

    def test_manually_disabled_rule_stays_disabled(self) -> None:
        review = self.correct(self.users[0])
        services.moderate_review(review=review, moderator=self.moderator, approve=True)
        ConfusionRule.objects.update(status="disabled")
        for u in self.users[1:4]:
            self.correct(u)
        self.assertEqual(ConfusionRule.objects.get().status, "disabled")

    def test_confirmation_is_stored_but_not_a_rule(self) -> None:
        for u in self.users[:3]:
            self.correct(u, correct="Sauce gombo")
        self.assertEqual(ScanReview.objects.count(), 3)
        self.assertFalse(ConfusionRule.objects.exists())

    def test_correct_label_is_required(self) -> None:
        with self.assertRaises(ValueError):
            self.correct(self.users[0], correct="  ")
