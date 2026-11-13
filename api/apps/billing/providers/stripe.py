"""
Adaptateur Stripe de l'interface `PaymentProvider` (API REST, sans SDK).

Webhooks : en-tête `Stripe-Signature` (`t=…,v1=…`), HMAC-SHA256 de `"{t}.{corps}"`, tolérance de 5 minutes.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import time
from datetime import UTC, datetime
from typing import Any, Final

import httpx
from django.conf import settings

from apps.billing.providers.base import (
    CheckoutSession,
    InvalidSignatureError,
    ProviderError,
    ProviderEvent,
    VerifiedSubscription,
)

API: Final = "https://api.stripe.com/v1"
TIMEOUT_S: Final = 10.0
SIGNATURE_TOLERANCE_S: Final = 300
STATUS_MAP: Final[dict[str, str]] = {
    "active": "active",
    "trialing": "active",
    "past_due": "grace",
    "unpaid": "expired",
    "canceled": "expired",
    "incomplete": "expired",
    "incomplete_expired": "expired",
    "paused": "expired",
}


def _ts(value: int | None) -> datetime:
    return datetime.fromtimestamp(int(value or 0), tz=UTC)


class StripeProvider:
    def __init__(self, *, secret_key: str | None = None, webhook_secret: str | None = None) -> None:
        self.secret_key = secret_key if secret_key is not None else settings.PAYMENTS_SECRET_KEY
        self.webhook_secret = webhook_secret if webhook_secret is not None else settings.PAYMENTS_WEBHOOK_SECRET

    def _post(self, path: str, data: dict[str, Any], *, idempotency_key: str | None = None) -> dict[str, Any]:
        if not self.secret_key:
            raise ProviderError("PAYMENTS_SECRET_KEY is not configured")
        headers = {"Idempotency-Key": idempotency_key} if idempotency_key else {}
        try:
            response = httpx.post(
                f"{API}{path}", data=data, auth=(self.secret_key, ""), headers=headers, timeout=TIMEOUT_S
            )
        except httpx.HTTPError as exc:
            raise ProviderError(f"stripe unreachable: {exc.__class__.__name__}") from exc
        if response.status_code >= 400:
            raise ProviderError(f"stripe {path} -> {response.status_code}")
        body: dict[str, Any] = response.json()
        return body

    def create_checkout(
        self,
        *,
        user_id: str,
        email: str,
        price_id: str,
        amount_off_cents: int,
        percent_off: int,
        success_url: str,
        cancel_url: str,
        idempotency_key: str,
    ) -> CheckoutSession:
        data: dict[str, Any] = {
            "mode": "subscription",
            "line_items[0][price]": price_id,
            "line_items[0][quantity]": 1,
            "client_reference_id": user_id,
            "customer_email": email,
            "success_url": success_url,
            "cancel_url": cancel_url,
            "subscription_data[metadata][user_id]": user_id,
        }
        if percent_off or amount_off_cents:
            coupon_data: dict[str, Any] = {"duration": "once"}
            if percent_off:
                coupon_data["percent_off"] = percent_off
            else:
                coupon_data.update({"amount_off": amount_off_cents, "currency": "usd"})
            coupon = self._post("/coupons", coupon_data, idempotency_key=f"{idempotency_key}-coupon")
            data["discounts[0][coupon]"] = coupon["id"]
        session = self._post("/checkout/sessions", data, idempotency_key=idempotency_key)
        return CheckoutSession(url=str(session["url"]), expires_at=_ts(session.get("expires_at")))

    def create_portal(self, *, customer_id: str, return_url: str) -> str:
        session = self._post("/billing_portal/sessions", {"customer": customer_id, "return_url": return_url})
        return str(session["url"])

    def refund(self, *, payment_external_id: str, amount_cents: int, idempotency_key: str) -> str:
        refund = self._post(
            "/refunds", {"payment_intent": payment_external_id, "amount": amount_cents}, idempotency_key=idempotency_key
        )
        return str(refund["id"])

    def verify_signature(self, *, body: bytes, header: str, now: float | None = None) -> None:
        if not self.webhook_secret:
            raise InvalidSignatureError("PAYMENTS_WEBHOOK_SECRET is not configured")
        parts = dict(item.split("=", 1) for item in header.split(",") if "=" in item)
        timestamp, signature = parts.get("t", ""), parts.get("v1", "")
        if not timestamp.isdigit() or not signature:
            raise InvalidSignatureError("malformed signature header")
        if abs((now or time.time()) - int(timestamp)) > SIGNATURE_TOLERANCE_S:
            raise InvalidSignatureError("signature too old")
        expected = hmac.new(self.webhook_secret.encode(), f"{timestamp}.".encode() + body, hashlib.sha256).hexdigest()
        if not hmac.compare_digest(expected, signature):
            raise InvalidSignatureError("signature mismatch")

    def parse_webhook(self, *, body: bytes, headers: dict[str, str]) -> ProviderEvent:
        self.verify_signature(body=body, header=headers.get("stripe-signature", ""))
        event = json.loads(body)
        obj: dict[str, Any] = event["data"]["object"]
        occurred_at = _ts(event.get("created"))
        kind = event["type"]
        if kind.startswith("customer.subscription."):
            metadata = obj.get("metadata") or {}
            item = (obj.get("items", {}).get("data") or [{}])[0]
            subscription = VerifiedSubscription(
                channel="web",
                external_id=str(obj["id"]),
                product_id=str((item.get("price") or {}).get("id", "")),
                status=STATUS_MAP.get(str(obj.get("status")), "expired"),
                period_start=_ts(obj.get("current_period_start") or item.get("current_period_start")),
                period_end=_ts(obj.get("current_period_end") or item.get("current_period_end")),
                auto_renew=not bool(obj.get("cancel_at_period_end")),
                event_at=occurred_at,
                raw={"customer": obj.get("customer"), "status": obj.get("status")},
            )
            return ProviderEvent(
                event_id=event["id"],
                type="subscription_updated",
                occurred_at=occurred_at,
                user_id=metadata.get("user_id"),
                subscription=subscription,
                raw=event,
            )
        if kind in ("invoice.paid", "invoice.payment_failed"):
            payment = {
                "external_id": str(obj.get("payment_intent") or obj["id"]),
                "subscription_external_id": obj.get("subscription"),
                "amount_cents": int(obj.get("amount_paid") or obj.get("amount_due") or 0),
                "receipt_url": obj.get("hosted_invoice_url") or "",
                "paid_at": occurred_at,
            }
            user_id = ((obj.get("subscription_details") or {}).get("metadata") or {}).get("user_id")
            kind_out = "payment_succeeded" if kind == "invoice.paid" else "payment_failed"
            return ProviderEvent(
                event_id=event["id"],
                type=kind_out,
                occurred_at=occurred_at,
                user_id=user_id,
                payment=payment,
                raw=event,
            )
        if kind == "charge.refunded":
            payment = {"external_id": str(obj.get("payment_intent") or obj["id"])}
            return ProviderEvent(
                event_id=event["id"], type="refunded", occurred_at=occurred_at, user_id=None, payment=payment, raw=event
            )
        return ProviderEvent(event_id=event["id"], type="ignored", occurred_at=occurred_at, user_id=None, raw=event)
