"""Authentification : inscription, connexion, MFA staff, rotation et rejeu des jetons, suspension, mots de passe."""

from __future__ import annotations

from collections.abc import Callable
from datetime import date, timedelta
from typing import Any

import pytest
from django.core import mail
from freezegun import freeze_time
from rest_framework.test import APIClient

from apps.accounts import mfa, one_time_tokens, services
from apps.accounts.models import Consent, OneTimeTokenPurpose, ReferralCode, Session, User
from apps.billing.models import Trial
from apps.nutrition.models import NutritionTarget
from conftest import CONSENTS, META, PASSWORD, login_client, totp_now

pytestmark = pytest.mark.django_db


def register_body(**overrides: Any) -> dict[str, Any]:
    body: dict[str, Any] = {
        "email": "Nouvelle@Example.com",
        "password": PASSWORD,
        "profile": {
            "first_name": "Awa",
            "last_name": "Diallo",
            "birth_date": "1996-03-14",
            "sex": "female",
            "height_cm": 175,
            "weight_kg": 78.4,
            "target_weight_kg": 74,
            "goals": ["lose_weight"],
            "timezone": "Africa/Douala",
        },
        "consents": CONSENTS,
        "device": {"name": "Pixel 8", "platform": "android", "app_version": "1.0.0", "fingerprint": "fp-new"},
    }
    body.update(overrides)
    return body


class TestRegister:
    def test_creates_everything(self, anon: APIClient, reference: None) -> None:
        response = anon.post("/api/v1/auth/register", register_body(), format="json")
        assert response.status_code == 201, response.json()
        body = response.json()
        assert body["created"] is True
        assert body["invite_code_status"] == "none"
        assert body["me"]["email"] == "nouvelle@example.com"
        assert body["me"]["email_verified"] is False
        assert body["me"]["entitlements"]["tier"] == "trial"
        assert body["me"]["targets"]["kcal"] > 0
        user = User.objects.get(email="nouvelle@example.com")
        assert user.password.startswith("argon2")
        assert Consent.objects.filter(user=user).count() == 3
        assert NutritionTarget.objects.filter(user=user).exists()
        assert ReferralCode.objects.filter(user=user).exists()
        trial = Trial.objects.get(user=user)
        assert (trial.ends_at - trial.starts_at).days == 3
        assert len(mail.outbox) == 1

    def test_duplicate_email_case_insensitive(self, anon: APIClient, user: User) -> None:
        response = anon.post("/api/v1/auth/register", register_body(email="AWA@example.com"), format="json")
        assert response.status_code == 409
        assert response.json()["code"] == "email_taken"

    @pytest.mark.parametrize("password", ["alllowercase1!", "ALLUPPERCASE1!", "NoDigitsHere!", "NoSymbol1234a"])
    def test_weak_password(self, anon: APIClient, reference: None, password: str) -> None:
        response = anon.post("/api/v1/auth/register", register_body(password=password), format="json")
        assert response.status_code == 400
        assert response.json()["code"] == "validation_error"
        assert "password" in response.json()["errors"]

    def test_missing_health_consent(self, anon: APIClient, reference: None) -> None:
        consents = [c for c in CONSENTS if c["kind"] != "health_data"]
        response = anon.post("/api/v1/auth/register", register_body(consents=consents), format="json")
        assert response.status_code == 400
        assert response.json()["meta"]["documents"] == ["health_data"]

    def test_too_young(self, anon: APIClient, reference: None) -> None:
        body = register_body()
        body["profile"]["birth_date"] = "2015-01-01"
        response = anon.post("/api/v1/auth/register", body, format="json")
        assert response.status_code == 400
        assert response.json()["errors"]["profile.birth_date"][0]["code"] == "too_young"

    def test_valid_invite_code_gives_7_days(self, anon: APIClient, user: User) -> None:
        code = ReferralCode.objects.get(user=user).code
        response = anon.post("/api/v1/auth/register", register_body(invite_code=code), format="json")
        assert response.json()["invite_code_status"] == "valid"
        trial = Trial.objects.get(user__email="nouvelle@example.com")
        assert (trial.ends_at - trial.starts_at).days == 7

    def test_invalid_invite_code_does_not_block(self, anon: APIClient, reference: None) -> None:
        response = anon.post("/api/v1/auth/register", register_body(invite_code="NOPE42"), format="json")
        assert response.status_code == 201
        assert response.json()["invite_code_status"] == "invalid"

    def test_problem_json_shape(self, anon: APIClient, reference: None) -> None:
        response = anon.post("/api/v1/auth/register", {}, format="json")
        assert response["Content-Type"].startswith("application/problem+json")
        body = response.json()
        assert body["type"] == "https://omeo.app/errors/validation_error"
        assert body["status"] == 400
        assert body["request_id"] == response["X-Request-Id"]


class TestLogin:
    def test_success(self, anon: APIClient, user: User) -> None:
        response = anon.post("/api/v1/auth/login", {"email": "AWA@example.com", "password": PASSWORD}, format="json")
        assert response.status_code == 200
        assert set(response.json()["tokens"]) == {"access", "refresh", "access_expires_at"}

    @pytest.mark.parametrize("email", ["awa@example.com", "unknown@example.com"])
    def test_invalid_credentials_same_answer(self, anon: APIClient, user: User, email: str) -> None:
        response = anon.post("/api/v1/auth/login", {"email": email, "password": "Wrong-pass1!"}, format="json")
        assert response.status_code == 401
        assert response.json()["code"] == "invalid_credentials"

    def test_suspended(self, anon: APIClient, user: User) -> None:
        services.suspend_user(user=user, actor=None, reason="test")
        response = anon.post("/api/v1/auth/login", {"email": user.email, "password": PASSWORD}, format="json")
        assert response.status_code == 403
        assert response.json()["code"] == "account_suspended"
        assert "support_url" in response.json()["meta"]

    def test_rate_limited(self, anon: APIClient, user: User) -> None:
        for _ in range(5):
            anon.post("/api/v1/auth/login", {"email": user.email, "password": "Wrong-pass1!"}, format="json")
        response = anon.post("/api/v1/auth/login", {"email": user.email, "password": PASSWORD}, format="json")
        assert response.status_code == 429
        assert response.json()["code"] == "rate_limited"
        assert int(response["Retry-After"]) > 0


class TestStaffMfa:
    def test_login_requires_mfa(self, anon: APIClient, superadmin: tuple[User, str]) -> None:
        staff, secret = superadmin
        response = anon.post("/api/v1/auth/login", {"email": staff.email, "password": PASSWORD}, format="json")
        assert response.status_code == 401
        assert response.json()["code"] == "mfa_required"
        token = response.json()["meta"]["mfa_token"]
        verified = anon.post("/api/v1/auth/mfa/verify", {"mfa_token": token, "code": totp_now(secret)}, format="json")
        assert verified.status_code == 200
        session = Session.objects.get(user=staff)
        assert session.mfa_verified_at is not None
        assert session.platform == "admin"

    def test_totp_code_cannot_be_replayed(self, anon: APIClient, superadmin: tuple[User, str]) -> None:
        staff, secret = superadmin
        code = totp_now(secret)
        for expected in (200, 401):
            token = anon.post("/api/v1/auth/login", {"email": staff.email, "password": PASSWORD}, format="json")
            response = anon.post(
                "/api/v1/auth/mfa/verify", {"mfa_token": token.json()["meta"]["mfa_token"], "code": code}, format="json"
            )
            assert response.status_code == expected

    def test_recovery_code_single_use(self, anon: APIClient, make_staff: Callable[..., tuple[User, str]]) -> None:
        staff, _ = make_staff("support")
        _, _, codes = mfa.enroll(staff)
        for expected in (200, 401):
            token = anon.post("/api/v1/auth/login", {"email": staff.email, "password": PASSWORD}, format="json")
            response = anon.post(
                "/api/v1/auth/mfa/verify",
                {"mfa_token": token.json()["meta"]["mfa_token"], "code": codes[0]},
                format="json",
            )
            assert response.status_code == expected

    def test_staff_idle_timeout(self, superadmin: tuple[User, str]) -> None:
        staff, _ = superadmin
        client = login_client(staff, mfa_verified=True)
        with freeze_time(timedelta(minutes=31)):
            response = client.get("/api/v1/me/sessions")
        assert response.status_code == 401

    def test_step_up(self, superadmin: tuple[User, str]) -> None:
        staff, secret = superadmin
        client = login_client(staff)
        response = client.post("/api/v1/auth/mfa/step-up", {"code": totp_now(secret)}, format="json")
        assert response.status_code == 200
        assert "mfa_verified_until" in response.json()

    def test_step_up_refused_for_app_user(self, api: APIClient) -> None:
        response = api.post("/api/v1/auth/mfa/step-up", {"code": "123456"}, format="json")
        assert response.status_code == 403
        assert response.json()["code"] == "forbidden_role"


class TestRefresh:
    def test_rotation(self, user: User) -> None:
        client = login_client(user)
        first = client.refresh_token  # type: ignore[attr-defined]
        response = APIClient().post("/api/v1/auth/refresh", {"refresh": first}, format="json")
        assert response.status_code == 200
        assert response.json()["refresh"] != first

    def test_reuse_revokes_session(self, user: User) -> None:
        client = login_client(user)
        stolen = client.refresh_token  # type: ignore[attr-defined]
        rotated = APIClient().post("/api/v1/auth/refresh", {"refresh": stolen}, format="json").json()["refresh"]
        replay = APIClient().post("/api/v1/auth/refresh", {"refresh": stolen}, format="json")
        assert replay.status_code == 401
        assert replay.json()["meta"]["reason"] == "refresh_reuse"
        # Le jeton légitime est mort aussi : toute la session est révoquée
        assert APIClient().post("/api/v1/auth/refresh", {"refresh": rotated}, format="json").status_code == 401
        assert Session.objects.get(user=user).revoked_reason == "refresh_reuse"
        assert client.get("/api/v1/me").status_code == 401

    def test_suspended_cannot_refresh(self, user: User) -> None:
        client = login_client(user)
        user.is_active = False
        user.save(update_fields=["is_active"])
        response = APIClient().post("/api/v1/auth/refresh", {"refresh": client.refresh_token}, format="json")  # type: ignore[attr-defined]
        assert response.status_code == 403
        assert response.json()["code"] == "account_suspended"

    def test_garbage(self, anon: APIClient, reference: None) -> None:
        response = anon.post("/api/v1/auth/refresh", {"refresh": "nope"}, format="json")
        assert response.status_code == 401
        assert response.json()["code"] == "token_expired"


class TestSuspension:
    def test_existing_access_token_refused_everywhere(self, api: APIClient, user: User) -> None:
        services.suspend_user(user=user, actor=None, reason="test")
        response = api.get("/api/v1/me")
        assert response.status_code in (401, 403)
        assert not Session.objects.filter(user=user, revoked_at__isnull=True).exists()

    def test_deactivated_without_service_still_refused(self, api: APIClient, user: User) -> None:
        User.objects.filter(pk=user.pk).update(is_active=False)
        response = api.get("/api/v1/me")
        assert response.status_code == 403
        assert response.json()["code"] == "account_suspended"


class TestLogout:
    def test_current_device(self, user: User) -> None:
        first, second = login_client(user), login_client(user)
        assert first.post("/api/v1/auth/logout", {}, format="json").status_code == 204
        assert first.get("/api/v1/me").status_code == 401
        assert second.get("/api/v1/me").status_code == 200

    def test_all_devices(self, user: User) -> None:
        first, second = login_client(user), login_client(user)
        first.post("/api/v1/auth/logout", {"all_devices": True}, format="json")
        assert second.get("/api/v1/me").status_code == 401


class TestPasswordReset:
    def test_forgot_never_reveals_account(self, anon: APIClient, user: User) -> None:
        for email in (user.email, "ghost@example.com"):
            assert anon.post("/api/v1/auth/password/forgot", {"email": email}, format="json").status_code == 204
        assert len(mail.outbox) == 1

    def test_reset_revokes_sessions(self, anon: APIClient, user: User) -> None:
        client = login_client(user)
        token = one_time_tokens.issue(user=user, purpose=OneTimeTokenPurpose.PASSWORD_RESET)
        response = anon.post("/api/v1/auth/password/reset", {"token": token, "password": "N0uveau-Secret"}, format="json")
        assert response.status_code == 204
        assert client.get("/api/v1/me").status_code == 401
        assert anon.post("/api/v1/auth/password/reset", {"token": token, "password": "Autre-S3cret!"}, format="json").status_code == 400

    def test_reset_token_expires(self, anon: APIClient, user: User) -> None:
        token = one_time_tokens.issue(user=user, purpose=OneTimeTokenPurpose.PASSWORD_RESET)
        with freeze_time(timedelta(hours=2)):
            response = anon.post("/api/v1/auth/password/reset", {"token": token, "password": "N0uveau-Secret"}, format="json")
        assert response.status_code == 400


class TestEmailVerification:
    def test_verify(self, anon: APIClient, make_user: Callable[..., User]) -> None:
        user = make_user(verified=False)
        token = one_time_tokens.issue(user=user, purpose=OneTimeTokenPurpose.EMAIL_VERIFY)
        assert anon.post("/api/v1/auth/email/verify", {"token": token}, format="json").status_code == 204
        user.refresh_from_db()
        assert user.email_verified_at is not None

    def test_change_email_requires_verified(self, make_user: Callable[..., User]) -> None:
        client = login_client(make_user(verified=False))
        response = client.post("/api/v1/me/email", {"email": "new@example.com", "password": PASSWORD}, format="json")
        assert response.status_code == 403
        assert response.json()["code"] == "email_not_verified"

    def test_change_email_flow(self, api: APIClient, user: User, anon: APIClient) -> None:
        assert api.post("/api/v1/me/email", {"email": "new@example.com", "password": PASSWORD}, format="json").status_code == 202
        token = one_time_tokens.issue(
            user=user, purpose=OneTimeTokenPurpose.EMAIL_CHANGE, payload={"new_email": "new@example.com"}
        )
        assert anon.post("/api/v1/auth/email/verify", {"token": token}, format="json").status_code == 204
        user.refresh_from_db()
        assert user.email == "new@example.com"


class TestInviteCode:
    def test_check(self, anon: APIClient, user: User) -> None:
        code = ReferralCode.objects.get(user=user).code
        response = anon.post("/api/v1/referral/check", {"code": code.lower()}, format="json")
        assert response.json() == {"valid": True, "referrer_first_name": "Awa", "trial_days": 7}

    def test_unknown(self, anon: APIClient, reference: None) -> None:
        response = anon.post("/api/v1/referral/check", {"code": "ZZZZ99"}, format="json")
        assert response.json()["valid"] is False


def test_create_account_service_is_reused_by_seed(reference: None) -> None:
    user, status = services.create_account(
        email="svc@example.com",
        password=PASSWORD,
        profile={
            "first_name": "A",
            "last_name": "B",
            "birth_date": date(1990, 1, 1),
            "sex": "male",
            "height_cm": 180,
            "weight_kg": 80,
            "target_weight_kg": 78,
            "goals": ["eat_balanced"],
        },
        consents=CONSENTS,
        invite_code=None,
        device=None,
        meta=META,
    )
    assert status == "none"
    assert not Session.objects.filter(user=user).exists()
