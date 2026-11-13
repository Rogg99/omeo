"""
Vérification des jetons d'identité Google et Apple (JWKS, signature RS256, émetteur, audience, expiration).

Apple : le `nonce` envoyé par l'app est haché en SHA-256 dans le jeton ; on compare l'empreinte.
"""

from __future__ import annotations

import hashlib
import hmac
from dataclasses import dataclass
from functools import cache
from typing import Final

import jwt
from django.conf import settings

from apps.core.errors import InvalidCredentials, ValidationFailed

GOOGLE_JWKS: Final = "https://www.googleapis.com/oauth2/v3/certs"
GOOGLE_ISSUERS: Final = ("https://accounts.google.com", "accounts.google.com")
APPLE_JWKS: Final = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER: Final = "https://appleid.apple.com"
LEEWAY_S: Final = 30


@dataclass(frozen=True, slots=True)
class SocialIdentity:
    provider: str
    subject: str
    email: str | None
    email_verified: bool


@cache
def _jwks_client(url: str) -> jwt.PyJWKClient:
    return jwt.PyJWKClient(url, cache_keys=True, lifespan=3600, timeout=5)


def _decode(token: str, *, jwks_url: str, audience: list[str], issuer: str | tuple[str, ...]) -> dict[str, object]:
    if not audience:
        raise InvalidCredentials(detail="provider not configured")
    try:
        key = _jwks_client(jwks_url).get_signing_key_from_jwt(token)
        claims: dict[str, object] = jwt.decode(
            token,
            key.key,
            algorithms=["RS256"],
            audience=audience,
            issuer=issuer,
            leeway=LEEWAY_S,
            options={"require": ["exp", "iat", "iss", "aud", "sub"]},
        )
    except (jwt.PyJWTError, jwt.PyJWKClientError):
        raise InvalidCredentials() from None
    return claims


def _as_bool(value: object) -> bool:
    return value is True or value == "true"


def verify_google(id_token: str) -> SocialIdentity:
    claims = _decode(
        id_token, jwks_url=GOOGLE_JWKS, audience=list(settings.GOOGLE_CLIENT_IDS), issuer=GOOGLE_ISSUERS
    )
    email = claims.get("email")
    return SocialIdentity(
        provider="google",
        subject=str(claims["sub"]),
        email=str(email).lower() if email else None,
        email_verified=_as_bool(claims.get("email_verified")),
    )


def verify_apple(identity_token: str, *, nonce: str | None) -> SocialIdentity:
    if not nonce:
        raise ValidationFailed(errors={"nonce": [{"code": "required", "message": "nonce required for Apple"}]})
    claims = _decode(
        identity_token, jwks_url=APPLE_JWKS, audience=list(settings.APPLE_CLIENT_IDS), issuer=APPLE_ISSUER
    )
    expected = hashlib.sha256(nonce.encode()).hexdigest()
    if not hmac.compare_digest(str(claims.get("nonce", "")), expected):
        raise InvalidCredentials()
    email = claims.get("email")
    return SocialIdentity(
        provider="apple",
        subject=str(claims["sub"]),
        email=str(email).lower() if email else None,
        email_verified=_as_bool(claims.get("email_verified")),
    )


def verify(provider: str, token: str, *, nonce: str | None) -> SocialIdentity:
    if provider == "google":
        return verify_google(token)
    if provider == "apple":
        return verify_apple(token, nonce=nonce)
    raise ValidationFailed(errors={"provider": [{"code": "invalid_choice", "message": "google or apple"}]})
