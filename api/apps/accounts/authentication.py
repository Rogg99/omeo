"""
Authentification DRF : JWT d'accès + session active + compte non suspendu.

Met `request.auth_session` à disposition (step-up, session courante). Applique l'inactivité staff (30 min)
et met à jour `Profile.timezone` depuis l'en-tête `X-Timezone`.
"""

from __future__ import annotations

from datetime import timedelta
from typing import Any, Final

from django.utils import timezone
from rest_framework.authentication import BaseAuthentication, get_authorization_header
from rest_framework.request import Request
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import AccessToken

from apps.accounts import tokens
from apps.accounts.models import Profile, Session, User
from apps.core.errors import TokenExpired
from apps.core.localtime import is_valid_timezone

TOUCH_EVERY: Final = timedelta(minutes=1)


class SessionJWTAuthentication(BaseAuthentication):
    keyword = b"bearer"

    def authenticate_header(self, request: Request) -> str:
        return 'Bearer realm="api"'

    def authenticate(self, request: Request) -> tuple[User, AccessToken] | None:
        header = get_authorization_header(request).split()
        if not header or header[0].lower() != self.keyword:
            return None
        if len(header) != 2:
            raise TokenExpired()
        try:
            access = AccessToken(header[1])  # type: ignore[arg-type]
        except TokenError:
            raise TokenExpired() from None
        session = tokens.session_from_access(access)
        user = session.user
        if not user.is_active:
            tokens.revoke_all(user, reason="suspended")
            raise tokens.suspended_error()
        now = timezone.now()
        if user.is_staff and now - session.last_used_at > tokens.STAFF_IDLE_TIMEOUT:
            tokens.revoke(session, reason="idle")
            raise TokenExpired(meta={"reason": "idle"})
        self._touch(session, user, now)
        self._sync_timezone(request, user)
        request.auth_session = session  # type: ignore[attr-defined]
        return user, access

    @staticmethod
    def _touch(session: Session, user: User, now: Any) -> None:
        if now - session.last_used_at >= TOUCH_EVERY:
            Session.objects.filter(pk=session.pk).update(last_used_at=now)
            User.objects.filter(pk=user.pk).update(last_seen_at=now)
            session.last_used_at = now

    @staticmethod
    def _sync_timezone(request: Request, user: User) -> None:
        wanted = request.headers.get("X-Timezone", "")
        profile: Profile | None = getattr(user, "profile", None)
        if not wanted or profile is None or wanted == profile.timezone or not is_valid_timezone(wanted):
            return
        Profile.objects.filter(pk=profile.pk).update(timezone=wanted, updated_at=timezone.now())
        profile.timezone = wanted
