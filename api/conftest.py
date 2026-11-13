"""Fixtures partagées : réglages de référence, comptes, client authentifié, staff avec TOTP."""

from __future__ import annotations

from collections.abc import Callable, Iterator
from datetime import date
from typing import Any

import pyotp
import pytest
from django.core.cache import cache
from django.core.management import call_command
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts import mfa, services
from apps.accounts.models import Role, StaffRole, User
from apps.accounts.tokens import open_session
from apps.core.audit import RequestMeta

PASSWORD = "Sup3r-Secret!"
META = RequestMeta(ip="127.0.0.1", user_agent="pytest")
CONSENTS = [
    {"kind": "terms", "granted": True},
    {"kind": "privacy", "granted": True},
    {"kind": "health_data", "granted": True},
]


def profile_payload(**overrides: Any) -> dict[str, Any]:
    data: dict[str, Any] = {
        "first_name": "Awa",
        "last_name": "Diallo",
        "birth_date": date(1996, 3, 14),
        "sex": "female",
        "height_cm": 175,
        "weight_kg": 78.4,
        "target_weight_kg": 74,
        "goals": ["lose_weight", "eat_balanced"],
        "timezone": "Africa/Douala",
    }
    data.update(overrides)
    return data


@pytest.fixture(autouse=True)
def _clear_cache() -> Iterator[None]:
    cache.clear()
    yield
    cache.clear()


@pytest.fixture(autouse=True)
def _email_backend(settings: Any) -> None:
    settings.EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
    settings.CELERY_TASK_ALWAYS_EAGER = True


@pytest.fixture
def reference(db: Any) -> None:
    call_command("seed_reference", verbosity=0)


@pytest.fixture
def make_user(reference: None) -> Callable[..., User]:
    counter = {"n": 0}

    def _make(*, email: str | None = None, verified: bool = True, **profile: Any) -> User:
        counter["n"] += 1
        user, _ = services.create_account(
            email=email or f"user{counter['n']}@example.com",
            password=PASSWORD,
            profile=profile_payload(**profile),
            consents=CONSENTS,
            invite_code=None,
            device=None,
            meta=META,
        )
        if verified:
            user.email_verified_at = timezone.now()
            user.save(update_fields=["email_verified_at"])
        return user

    return _make


@pytest.fixture
def user(make_user: Callable[..., User]) -> User:
    return make_user(email="awa@example.com")


def login_client(user: User, *, mfa_verified: bool = False) -> APIClient:
    _, pair = open_session(
        user=user, device={"name": "pytest", "platform": "android"}, ip="127.0.0.1", mfa_verified=mfa_verified
    )
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {pair.access}")
    client.refresh_token = pair.refresh  # type: ignore[attr-defined]
    return client


@pytest.fixture
def api(user: User) -> APIClient:
    return login_client(user)


@pytest.fixture
def anon() -> APIClient:
    return APIClient()


@pytest.fixture
def make_staff(reference: None) -> Callable[..., tuple[User, str]]:
    def _make(*roles: str, email: str | None = None) -> tuple[User, str]:
        staff = User.objects.create_user(
            email=email or f"{'-'.join(roles) or 'none'}-{User.objects.count()}@staff.omeo.app",
            password=PASSWORD,
            is_staff=True,
        )
        for role in roles:
            StaffRole.objects.create(user=staff, role=role)
        secret, _, _ = mfa.enroll(staff)
        return staff, secret

    return _make


@pytest.fixture
def superadmin(make_staff: Callable[..., tuple[User, str]]) -> tuple[User, str]:
    return make_staff(Role.SUPERADMIN)


def totp_now(secret: str) -> str:
    return pyotp.TOTP(secret).now()
