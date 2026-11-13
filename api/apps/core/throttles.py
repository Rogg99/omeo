"""
Limites de débit (conventions-api.md) :
- `/auth/login`, `/auth/password/forgot`, `/auth/mfa/verify` : 5/min par IP ET par compte ;
- `/auth/register` : 10/h par IP ;
- formulaires publics : 5/h par IP (plus captcha) ; lectures publiques : 60/min par IP ;
- utilisateur connecté : 120/min ; staff : 600/min.
"""

from __future__ import annotations

import hashlib
from typing import Any

from rest_framework.request import Request
from rest_framework.throttling import SimpleRateThrottle
from rest_framework.views import APIView


class IpThrottle(SimpleRateThrottle):
    def get_cache_key(self, request: Request, view: APIView) -> str | None:
        return self.cache_format % {"scope": self.scope, "ident": self.get_ident(request)}


class AuthIpThrottle(IpThrottle):
    scope = "auth"


class AuthAccountThrottle(SimpleRateThrottle):
    """Par compte visé (email ou jeton MFA), pour freiner le bourrage d'identifiants réparti sur plusieurs IP."""

    scope = "auth"

    def get_cache_key(self, request: Request, view: APIView) -> str | None:
        data: Any = request.data if isinstance(request.data, dict) else {}
        ident = str(data.get("email") or data.get("mfa_token") or "").strip().lower()
        if not ident:
            return None
        digest = hashlib.sha256(ident.encode()).hexdigest()[:32]
        return self.cache_format % {"scope": f"{self.scope}_account", "ident": digest}


class RegisterThrottle(IpThrottle):
    scope = "register"


class PublicFormThrottle(IpThrottle):
    scope = "public_form"


class PublicReadThrottle(IpThrottle):
    """Lectures publiques (configuration, villes, contenus légaux)."""

    scope = "public_read"


class UserThrottle(SimpleRateThrottle):
    """120/min pour l'app, 600/min pour le staff. Ignore les requêtes anonymes (gérées par les throttles d'IP)."""

    scope = "user"

    def allow_request(self, request: Request, view: APIView) -> bool:
        user = request.user
        if user and user.is_authenticated and getattr(user, "is_staff", False):
            self.scope = "staff"
        else:
            self.scope = "user"
        self.rate = self.get_rate()
        self.num_requests, self.duration = self.parse_rate(self.rate)
        return super().allow_request(request, view)

    def get_cache_key(self, request: Request, view: APIView) -> str | None:
        if not request.user or not request.user.is_authenticated:
            return None
        return self.cache_format % {"scope": self.scope, "ident": request.user.pk}
