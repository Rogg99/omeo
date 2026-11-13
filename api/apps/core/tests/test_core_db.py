"""Socle avec base : idempotence, quatre yeux, réglages, audit, chiffrement, seeds."""

from __future__ import annotations

import uuid
from collections.abc import Callable
from decimal import Decimal
from typing import Any

import pytest
from django.core.management import call_command
from django.core.cache import cache
from django.core.management.base import CommandError
from django.db import IntegrityError, connection
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import LegalDocument, User
from apps.core import crypto, settings_store, storage
from apps.core.approvals import ApprovalService, register_executor
from apps.core.errors import ApprovalPending, ForbiddenRole, SelfApprovalForbidden
from apps.core.management.commands.seed_reference import clean_legal_markdown, placeholders_in
from apps.core.models import ApprovalRequest, AuditLog, Setting
from conftest import login_client

pytestmark = pytest.mark.django_db


class TestIdempotency:
    @pytest.fixture(autouse=True)
    def _fake_storage(self, monkeypatch: pytest.MonkeyPatch) -> None:
        def presign(**kwargs: Any) -> storage.PresignedUpload:
            return storage.PresignedUpload(
                key=kwargs["key"], url="http://s3.test/put", method="PUT", headers={}, expires_at=timezone.now()
            )

        monkeypatch.setattr(storage, "presign_upload", presign)

    def _post(self, client: APIClient, key: str, size: int = 1000) -> Any:
        return client.post(
            "/api/v1/me/uploads",
            {"kind": "meal_photo", "content_type": "image/jpeg", "size": size},
            format="json",
            HTTP_IDEMPOTENCY_KEY=key,
        )

    def test_replay_returns_same_response(self, api: APIClient) -> None:
        key = str(uuid.uuid4())
        first, second = self._post(api, key), self._post(api, key)
        assert first.status_code == second.status_code == 201
        assert first.json()["id"] == second.json()["id"]
        assert second["Idempotent-Replayed"] == "true"

    def test_same_key_other_body_conflicts(self, api: APIClient) -> None:
        key = str(uuid.uuid4())
        self._post(api, key)
        response = self._post(api, key, size=2000)
        assert response.status_code == 409
        assert response.json()["code"] == "idempotency_conflict"

    def test_key_is_per_user(self, api: APIClient, make_user: Callable[..., User]) -> None:
        key = str(uuid.uuid4())
        mine = self._post(api, key)
        theirs = self._post(login_client(make_user()), key)
        assert mine.json()["id"] != theirs.json()["id"]

    def test_missing_key(self, api: APIClient) -> None:
        response = api.post(
            "/api/v1/me/uploads", {"kind": "meal_photo", "content_type": "image/jpeg", "size": 1}, format="json"
        )
        assert response.status_code == 400
        assert "Idempotency-Key" in response.json()["errors"]

    def test_survives_cache_loss(self, api: APIClient) -> None:
        key = str(uuid.uuid4())
        first = self._post(api, key)
        cache.clear()
        assert self._post(api, key).json()["id"] == first.json()["id"]


class TestFourEyes:
    @pytest.fixture(autouse=True)
    def _executor(self) -> None:
        def apply(approval: ApprovalRequest, decider: Any) -> dict[str, Any]:
            settings_store.set_value(approval.payload["key"], approval.payload["value"], updated_by_id=decider.pk)
            return {"value": approval.payload["value"]}

        register_executor("settings_nutrition", apply)

    def _request(self, requester: User) -> ApprovalRequest:
        return ApprovalService.create(
            kind="settings_nutrition",
            payload={"key": "nutrition.salt_max_g", "value": 4},
            diff={"before": {"value": 5}, "after": {"value": 4}},
            target_type="setting",
            target_id="nutrition.salt_max_g",
            reason="Recommandation mise à jour",
            requested_by=requester,
        )

    def test_approve_replays_action(self, superadmin: tuple[User, str], make_staff: Callable[..., Any]) -> None:
        requester, _ = superadmin
        decider, _ = make_staff("superadmin")
        approval = self._request(requester)
        ApprovalService.approve(approval_id=approval.pk, decider=decider)
        assert Setting.objects.get(key="nutrition.salt_max_g").value == 4
        assert AuditLog.objects.filter(action="approval.approve.settings_nutrition", actor=decider).exists()

    def test_self_approval_forbidden_even_superadmin(self, superadmin: tuple[User, str]) -> None:
        requester, _ = superadmin
        approval = self._request(requester)
        with pytest.raises(SelfApprovalForbidden):
            ApprovalService.approve(approval_id=approval.pk, decider=requester)

    def test_db_constraint(self, superadmin: tuple[User, str]) -> None:
        requester, _ = superadmin
        approval = self._request(requester)
        with pytest.raises(IntegrityError):
            ApprovalRequest.objects.filter(pk=approval.pk).update(decided_by=requester)

    def test_wrong_domain(self, superadmin: tuple[User, str], make_staff: Callable[..., Any]) -> None:
        requester, _ = superadmin
        content_lead, _ = make_staff("content")
        approval = self._request(requester)
        with pytest.raises(ForbiddenRole):
            ApprovalService.approve(approval_id=approval.pk, decider=content_lead)

    def test_single_pending_per_target(self, superadmin: tuple[User, str]) -> None:
        requester, _ = superadmin
        self._request(requester)
        with pytest.raises(ApprovalPending):
            self._request(requester)


class TestSettingsStore:
    def test_prefix_and_key(self, reference: None) -> None:
        assert settings_store.get("nutrition.salt_max_g") == 5
        assert settings_store.get("nutrition")["min_kcal"] == {"female": 1200, "male": 1500}

    def test_missing_raises(self, reference: None) -> None:
        with pytest.raises(KeyError):
            settings_store.get("nope.nothing")


class TestAudit:
    def test_append_only(self) -> None:
        entry = AuditLog.objects.create(action="test")
        with pytest.raises(ValueError, match="append-only"):
            entry.save()
        with pytest.raises(ValueError, match="append-only"):
            entry.delete()


class TestEncryption:
    def test_roundtrip_and_ciphertext_at_rest(self) -> None:
        field = crypto.EncryptedDecimalField(decimal_places=2)
        stored = field.get_prep_value(Decimal("78.4"))
        assert stored is not None
        assert "78" not in stored
        assert field.from_db_value(stored, None, connection) == Decimal("78.40")


class TestSeedReference:
    def test_idempotent_and_never_overwrites(self) -> None:
        call_command("seed_reference", verbosity=0)
        Setting.objects.filter(key="nutrition.salt_max_g").update(value=4)
        counts = (Setting.objects.count(), LegalDocument.objects.count())
        call_command("seed_reference", verbosity=0)
        assert (Setting.objects.count(), LegalDocument.objects.count()) == counts
        assert Setting.objects.get(key="nutrition.salt_max_g").value == 4

    def test_dry_run_writes_nothing(self) -> None:
        call_command("seed_reference", "--dry-run", verbosity=0)
        assert not Setting.objects.exists()

    def test_production_refuses_placeholders(self, settings: Any) -> None:
        settings.IS_PRODUCTION = True
        with pytest.raises(CommandError, match="placeholders"):
            call_command("seed_reference", verbosity=0)

    def test_placeholder_detection(self) -> None:
        text = clean_legal_markdown("<!-- [commentaire] -->Éditeur : [Raison sociale]. Voir [CGU](https://omeo.app).")
        assert placeholders_in(text) == ["[Raison sociale]"]


class TestSeedDemo:
    def test_refused_in_production(self, settings: Any, reference: None) -> None:
        settings.IS_PRODUCTION = True
        with pytest.raises(CommandError):
            call_command("seed_demo", verbosity=0)

    def test_deterministic_accounts(self, reference: None) -> None:
        call_command("seed_demo", verbosity=0)
        first = sorted(User.objects.filter(email__endswith="@demo.omeo.app").values_list("email", "profile__birth_date"))
        call_command("seed_demo", "--reset", verbosity=0)
        second = sorted(User.objects.filter(email__endswith="@demo.omeo.app").values_list("email", "profile__birth_date"))
        assert first == second
        assert not User.objects.get(email="suspendu@demo.omeo.app").is_active
        assert User.objects.get(email="awa@demo.omeo.app").profile.city is not None
