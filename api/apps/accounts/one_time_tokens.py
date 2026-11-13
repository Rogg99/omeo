"""Jetons à usage unique envoyés par email (vérification, réinitialisation, changement d'email, suppression)."""

from __future__ import annotations

import hashlib
import secrets
from datetime import timedelta
from typing import Any, Final

from django.db import transaction
from django.utils import timezone

from apps.accounts.models import OneTimeToken, OneTimeTokenPurpose, User
from apps.core.errors import ValidationFailed

LIFETIMES: Final[dict[str, timedelta]] = {
    OneTimeTokenPurpose.EMAIL_VERIFY: timedelta(days=7),
    OneTimeTokenPurpose.PASSWORD_RESET: timedelta(hours=1),
    OneTimeTokenPurpose.EMAIL_CHANGE: timedelta(hours=24),
    OneTimeTokenPurpose.ACCOUNT_DELETION: timedelta(hours=24),
}


def _hash(raw: str) -> str:
    return hashlib.sha256(raw.encode()).hexdigest()


@transaction.atomic
def issue(*, user: User, purpose: str, payload: dict[str, Any] | None = None) -> str:
    """Invalide les jetons précédents du même usage, puis en émet un nouveau. Renvoie le jeton en clair."""
    now = timezone.now()
    OneTimeToken.objects.filter(user=user, purpose=purpose, used_at__isnull=True).update(used_at=now)
    raw = secrets.token_urlsafe(32)
    OneTimeToken.objects.create(
        user=user,
        purpose=purpose,
        token_hash=_hash(raw),
        payload=payload or {},
        expires_at=now + LIFETIMES[purpose],
    )
    return raw


@transaction.atomic
def consume(*, raw: str, purpose: str) -> OneTimeToken:
    token = (
        OneTimeToken.objects.select_for_update()
        .select_related("user")
        .filter(token_hash=_hash(raw), purpose=purpose, used_at__isnull=True, expires_at__gt=timezone.now())
        .first()
    )
    if token is None:
        raise ValidationFailed(errors={"token": [{"code": "invalid_token", "message": "invalid or expired token"}]})
    token.used_at = timezone.now()
    token.save(update_fields=["used_at", "updated_at"])
    return token
