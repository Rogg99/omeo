"""
Jetons JWT liés à une `Session`.

- Accès : 15 min (10 min pour le staff), claim `sid` = session.
- Renouvellement : 30 jours (12 h maximum pour le staff), rotation à chaque usage. `Session.refresh_jti` contient le
  SEUL jti valide : présenter un autre jti de la même session est un rejeu (vol probable), la session est révoquée.
- Staff : session fermée après 30 min d'inactivité.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any, Final

from django.db import transaction
from django.utils import timezone
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import AccessToken, RefreshToken

from apps.accounts.models import Session, User
from apps.core.errors import AccountSuspended, NotAuthenticated, TokenExpired
from apps.core.ids import uuid7

ACCESS_TTL: Final = timedelta(minutes=15)
STAFF_ACCESS_TTL: Final = timedelta(minutes=10)
REFRESH_TTL: Final = timedelta(days=30)
STAFF_SESSION_MAX: Final = timedelta(hours=12)
STAFF_IDLE_TIMEOUT: Final = timedelta(minutes=30)
SUPPORT_URL: Final = "https://omeo.app/support"


@dataclass(frozen=True, slots=True)
class TokenPair:
    access: str
    refresh: str
    access_expires_at: datetime

    def as_dict(self) -> dict[str, Any]:
        return {"access": self.access, "refresh": self.refresh, "access_expires_at": self.access_expires_at}


def suspended_error() -> AccountSuspended:
    return AccountSuspended(meta={"support_url": SUPPORT_URL})


def _issue(session: Session, user: User) -> TokenPair:
    now = timezone.now()
    jti = uuid7().hex
    refresh = RefreshToken()
    refresh.set_exp(from_time=now, lifetime=min(REFRESH_TTL, session.expires_at - now))
    refresh["jti"] = jti
    refresh["sid"] = str(session.pk)
    refresh["user_id"] = str(user.pk)

    access = AccessToken()
    lifetime = STAFF_ACCESS_TTL if user.is_staff else ACCESS_TTL
    access.set_exp(from_time=now, lifetime=lifetime)
    access["sid"] = str(session.pk)
    access["user_id"] = str(user.pk)

    session.refresh_jti = jti
    session.last_used_at = now
    session.save(update_fields=["refresh_jti", "last_used_at", "updated_at"])
    return TokenPair(access=str(access), refresh=str(refresh), access_expires_at=now + lifetime)


@transaction.atomic
def open_session(
    *,
    user: User,
    device: dict[str, Any] | None,
    ip: str | None,
    mfa_verified: bool = False,
) -> tuple[Session, TokenPair]:
    if not user.is_active:
        raise suspended_error()
    device = device or {}
    now = timezone.now()
    platform = "admin" if user.is_staff else (device.get("platform") or "android")
    session = Session.objects.create(
        user=user,
        refresh_jti=uuid7().hex,
        device_name=(device.get("name") or "")[:80],
        platform=platform,
        app_version=(device.get("app_version") or "")[:20],
        ip=ip,
        last_used_at=now,
        expires_at=now + (STAFF_SESSION_MAX if user.is_staff else REFRESH_TTL),
        mfa_verified_at=now if mfa_verified else None,
    )
    User.objects.filter(pk=user.pk).update(last_seen_at=now)
    return session, _issue(session, user)


@transaction.atomic
def rotate(raw_refresh: str) -> TokenPair:
    try:
        token = RefreshToken(raw_refresh)  # type: ignore[arg-type]
    except TokenError:
        raise TokenExpired() from None
    session = Session.objects.select_for_update().select_related("user").filter(pk=token.get("sid")).first()
    if session is None or session.revoked_at is not None:
        raise TokenExpired()
    if session.refresh_jti != token.get("jti"):
        revoke(session, reason="refresh_reuse")
        raise TokenExpired(meta={"reason": "refresh_reuse"})
    user = session.user
    if not user.is_active:
        revoke(session, reason="suspended")
        raise suspended_error()
    now = timezone.now()
    if session.expires_at <= now or (user.is_staff and now - session.last_used_at > STAFF_IDLE_TIMEOUT):
        revoke(session, reason="expired")
        raise TokenExpired()
    return _issue(session, user)


def revoke(session: Session, *, reason: str) -> None:
    Session.objects.filter(pk=session.pk, revoked_at__isnull=True).update(
        revoked_at=timezone.now(), revoked_reason=reason
    )


def revoke_all(user: User, *, reason: str, except_session: Session | None = None) -> int:
    queryset = Session.objects.filter(user=user, revoked_at__isnull=True)
    if except_session is not None:
        queryset = queryset.exclude(pk=except_session.pk)
    return queryset.update(revoked_at=timezone.now(), revoked_reason=reason)


def session_from_access(raw: AccessToken) -> Session:
    session = Session.objects.select_related("user", "user__profile").filter(pk=raw.get("sid")).first()
    if session is None or session.revoked_at is not None:
        raise TokenExpired()
    if str(session.user_id) != str(raw.get("user_id")):
        raise NotAuthenticated()
    return session
