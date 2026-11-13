"""
Google Play : vérification des abonnements (Play Developer API, `purchases.subscriptionsv2`) et authentification
des notifications RTDN (push Pub/Sub, jeton OIDC signé par Google pour notre compte de service).
"""

from __future__ import annotations

import base64
import json
from datetime import UTC, datetime
from typing import Any, Final

import httpx
from django.conf import settings
from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2 import id_token as google_id_token
from google.oauth2 import service_account

from apps.billing.providers.base import InvalidSignatureError, ProviderError, VerifiedSubscription

SCOPE: Final = "https://www.googleapis.com/auth/androidpublisher"
API: Final = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
TIMEOUT_S: Final = 10.0
STATE_MAP: Final[dict[str, str]] = {
    "SUBSCRIPTION_STATE_ACTIVE": "active",
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD": "grace",
    "SUBSCRIPTION_STATE_CANCELED": "canceled",
    "SUBSCRIPTION_STATE_ON_HOLD": "expired",
    "SUBSCRIPTION_STATE_PAUSED": "expired",
    "SUBSCRIPTION_STATE_EXPIRED": "expired",
}


def _parse_time(value: str | None) -> datetime:
    if not value:
        return datetime.now(UTC)
    return datetime.fromisoformat(value)


def _access_token() -> str:
    info = settings.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
    if not info:
        raise ProviderError("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON is not configured")
    credentials = service_account.Credentials.from_service_account_info(json.loads(info), scopes=[SCOPE])
    credentials.refresh(GoogleRequest())
    return str(credentials.token)


def verify_subscription(*, purchase_token: str) -> VerifiedSubscription:
    url = f"{API}/{settings.GOOGLE_PLAY_PACKAGE_NAME}/purchases/subscriptionsv2/tokens/{purchase_token}"
    try:
        response = httpx.get(url, headers={"Authorization": f"Bearer {_access_token()}"}, timeout=TIMEOUT_S)
    except httpx.HTTPError as exc:
        raise ProviderError(f"google play unreachable: {exc.__class__.__name__}") from exc
    if response.status_code == 404:
        raise ProviderError("unknown purchase token")
    if response.status_code >= 400:
        raise ProviderError(f"google play -> {response.status_code}")
    data: dict[str, Any] = response.json()
    item = (data.get("lineItems") or [{}])[0]
    return VerifiedSubscription(
        channel="google_play",
        external_id=purchase_token,
        product_id=str(item.get("productId", "")),
        status=STATE_MAP.get(str(data.get("subscriptionState")), "expired"),
        period_start=_parse_time(data.get("startTime")),
        period_end=_parse_time(item.get("expiryTime")),
        auto_renew=bool((item.get("autoRenewingPlan") or {}).get("autoRenewEnabled", False)),
        event_at=datetime.now(UTC),
        raw={
            "subscriptionState": data.get("subscriptionState"),
            "acknowledgementState": data.get("acknowledgementState"),
        },
    )


def verify_push_token(authorization: str) -> None:
    """Jeton OIDC de Pub/Sub : signature Google, audience et compte de service attendus."""
    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise InvalidSignatureError("missing OIDC token")
    try:
        claims = google_id_token.verify_oauth2_token(token, GoogleRequest(), audience=settings.GOOGLE_PUBSUB_AUDIENCE)
    except ValueError as exc:
        raise InvalidSignatureError("invalid OIDC token") from exc
    if claims.get("email") != settings.GOOGLE_PUBSUB_SERVICE_ACCOUNT or not claims.get("email_verified"):
        raise InvalidSignatureError("unexpected service account")


def parse_push(body: dict[str, Any]) -> tuple[str, datetime, dict[str, Any]]:
    """(identifiant du message, date de publication, notification décodée)."""
    message = body.get("message") or {}
    data = json.loads(base64.b64decode(message.get("data", "")) or b"{}")
    return str(message.get("messageId", "")), _parse_time(message.get("publishTime")), data
