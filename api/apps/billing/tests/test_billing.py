"""Billing : prix, signature des webhooks, abonnements (désordre, idempotence), paiement web, promo, parrainage."""

from __future__ import annotations

import hashlib
import hmac
import json
import time
import uuid
from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from typing import Any

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts import services as accounts
from apps.accounts.models import DeviceFingerprint, Referral, ReferralCode, User
from apps.billing import pricing, subscriptions
from apps.billing.models import GrantedDays, Plan, PromoCode, Subscription, WebhookEvent
from apps.billing.providers.base import CheckoutSession, InvalidSignatureError, VerifiedSubscription
from apps.billing.providers.stripe import StripeProvider
from apps.billing.services import entitlement_for, invalidate_entitlement
from apps.nutrition.models import DailySummary
from conftest import CONSENTS, META, PASSWORD, profile_payload

NOW = datetime(2026, 11, 13, 12, tzinfo=UTC)


class TestPricing:
    def test_percent_and_amount(self) -> None:
        assert pricing.apply_discount(449, pricing.Discount("percent", 20)) == 359
        assert pricing.apply_discount(449, pricing.Discount("amount", 500)) == 0
        assert pricing.apply_discount(449, pricing.Discount("free_days", 7)) == 449

    def test_annual(self) -> None:
        assert pricing.monthly_equivalent(4699, "year") == 392
        assert pricing.savings_percent(annual_cents=4699, monthly_cents=449) == 13
        assert pricing.monthly_equivalent(449, "month") is None

    def test_format(self) -> None:
        assert pricing.format_usd(449, "fr") == "4,49 $"
        assert pricing.format_usd(449, "en") == "$4.49"


class TestStripeSignature:
    SECRET = "whsec_test"

    def _header(self, body: bytes, timestamp: int) -> str:
        digest = hmac.new(self.SECRET.encode(), f"{timestamp}.".encode() + body, hashlib.sha256).hexdigest()
        return f"t={timestamp},v1={digest}"

    def test_valid(self) -> None:
        body = b'{"id": "evt_1"}'
        StripeProvider(webhook_secret=self.SECRET).verify_signature(
            body=body, header=self._header(body, int(time.time()))
        )

    def test_tampered(self) -> None:
        header = self._header(b'{"id": "evt_1"}', int(time.time()))
        with pytest.raises(InvalidSignatureError):
            StripeProvider(webhook_secret=self.SECRET).verify_signature(body=b'{"id": "evt_2"}', header=header)

    def test_replayed_too_late(self) -> None:
        body = b"{}"
        with pytest.raises(InvalidSignatureError):
            StripeProvider(webhook_secret=self.SECRET).verify_signature(
                body=body, header=self._header(body, int(time.time()) - 3600)
            )


def verified(status: str, *, event_at: datetime, end: datetime, external_id: str = "tok-1") -> VerifiedSubscription:
    return VerifiedSubscription(
        channel="google_play",
        external_id=external_id,
        product_id="omeo_plus_monthly",
        status=status,
        period_start=end - timedelta(days=30),
        period_end=end,
        auto_renew=status == "active",
        event_at=event_at,
    )


@pytest.mark.django_db
class TestSubscriptions:
    def test_apply_and_entitlement(self, user: User) -> None:
        now = timezone.now()
        subscriptions.apply_verified(user=user, verified=verified("active", event_at=now, end=now + timedelta(days=30)))
        invalidate_entitlement(user.pk)
        assert entitlement_for(user).tier == "plus"

    def test_out_of_order_event_ignored(self, user: User) -> None:
        now = timezone.now()
        subscriptions.apply_verified(user=user, verified=verified("expired", event_at=now, end=now - timedelta(days=1)))
        subscriptions.apply_verified(
            user=user, verified=verified("active", event_at=now - timedelta(hours=1), end=now + timedelta(days=30))
        )
        assert Subscription.objects.get().status == "expired"

    def test_purchase_of_another_account(self, user: User, make_user: Callable[..., User]) -> None:
        now = timezone.now()
        subscriptions.apply_verified(user=user, verified=verified("active", event_at=now, end=now + timedelta(days=30)))
        with pytest.raises(Exception, match="another account"):
            subscriptions.apply_verified(
                user=make_user(), verified=verified("active", event_at=now, end=now + timedelta(days=30))
            )

    def test_payments_webhook_idempotent(self, user: User, settings: Any) -> None:
        settings.PAYMENTS_WEBHOOK_SECRET = "whsec_test"
        now = int(time.time())
        event = {
            "id": "evt_dup",
            "type": "customer.subscription.updated",
            "created": now,
            "data": {
                "object": {
                    "id": "sub_1",
                    "status": "active",
                    "customer": "cus_1",
                    "cancel_at_period_end": False,
                    "current_period_start": now,
                    "current_period_end": now + 30 * 86400,
                    "metadata": {"user_id": str(user.pk)},
                    "items": {"data": [{"price": {"id": "price_monthly"}}]},
                }
            },
        }
        Plan.objects.filter(code="plus_monthly").update(web_price_id="price_monthly")
        body = json.dumps(event).encode()
        digest = hmac.new(b"whsec_test", f"{now}.".encode() + body, hashlib.sha256).hexdigest()
        headers = {"stripe-signature": f"t={now},v1={digest}"}
        client = APIClient()
        for _ in range(2):
            response = client.generic(
                "POST",
                "/api/v1/webhooks/payments",
                body,
                content_type="application/json",
                HTTP_STRIPE_SIGNATURE=headers["stripe-signature"],
            )
            assert response.status_code == 204
        assert WebhookEvent.objects.count() == 1
        assert Subscription.objects.get(channel="web").raw["customer"] == "cus_1"

    def test_bad_signature_is_401(self, reference: None, settings: Any) -> None:
        settings.PAYMENTS_WEBHOOK_SECRET = "whsec_test"
        response = APIClient().generic(
            "POST",
            "/api/v1/webhooks/payments",
            b"{}",
            content_type="application/json",
            HTTP_STRIPE_SIGNATURE="t=1,v1=x",
        )
        assert response.status_code == 401


@pytest.mark.django_db
class TestWebCheckout:
    @pytest.fixture(autouse=True)
    def provider_calls(self, monkeypatch: pytest.MonkeyPatch) -> list[dict[str, Any]]:
        calls: list[dict[str, Any]] = []

        class Fake:
            def create_checkout(self, **kwargs: Any) -> CheckoutSession:
                calls.append(kwargs)
                return CheckoutSession(url="https://pay.test/s/1", expires_at=timezone.now() + timedelta(hours=1))

        monkeypatch.setattr(subscriptions, "payment_provider", Fake)
        Plan.objects.filter(code__startswith="plus").update(web_price_id="price_x")
        return calls

    def _post(self, client: APIClient, **body: Any) -> Any:
        payload = {
            "plan_code": "plus_monthly",
            "success_url": "https://omeo.app/ok",
            "cancel_url": "https://omeo.app/ko",
            **body,
        }
        return client.post(
            "/api/v1/me/billing/checkout", payload, format="json", HTTP_IDEMPOTENCY_KEY=str(uuid.uuid4())
        )

    def test_checkout(self, api: APIClient) -> None:
        response = self._post(api)
        assert response.status_code == 201
        assert response.json()["checkout_url"] == "https://pay.test/s/1"

    def test_store_subscription_conflict(self, api: APIClient, user: User) -> None:
        now = timezone.now()
        subscriptions.apply_verified(user=user, verified=verified("active", event_at=now, end=now + timedelta(days=30)))
        assert self._post(api).status_code == 409

    def test_promo_applied_once(self, api: APIClient, provider_calls: list[dict[str, Any]]) -> None:
        PromoCode.objects.create(code="BIENVENUE", kind="percent", value=20)
        check = api.post(
            "/api/v1/me/billing/promo-check", {"code": "bienvenue", "plan_code": "plus_monthly"}, format="json"
        )
        assert check.json()["discounted"]["amount_cents"] == 359
        assert self._post(api, promo_code="BIENVENUE").status_code == 201
        assert provider_calls[0]["percent_off"] == 20
        assert self._post(api, promo_code="BIENVENUE").status_code == 400

    def test_requires_verified_email(self, make_user: Callable[..., User]) -> None:
        from conftest import login_client

        response = self._post(login_client(make_user(verified=False)))
        assert response.status_code == 403
        assert response.json()["code"] == "email_not_verified"


@pytest.mark.django_db
class TestReferral:
    def _register_referee(self, code: str, fingerprint: str) -> User:
        user, status = accounts.create_account(
            email=f"{fingerprint}@example.com",
            password=PASSWORD,
            profile=profile_payload(first_name="Kofi"),
            consents=CONSENTS,
            invite_code=code,
            device={"fingerprint": fingerprint},
            meta=META,
        )
        assert status == "valid"
        return user

    def _complete(self, referee: User) -> None:
        DailySummary.objects.create(user=referee, date=timezone.localdate(), meals_count=1)
        referee.email_verified_at = timezone.now()
        referee.save()
        accounts.evaluate_referral(referee_id=referee.pk)

    def test_validated_grants_days(self, user: User) -> None:
        code = ReferralCode.objects.get(user=user).code
        referee = self._register_referee(code, "fp-referee")
        self._complete(referee)
        referral = Referral.objects.get(referee=referee)
        assert referral.status == "validated"
        assert GrantedDays.objects.get(user=user).days == 7

    def test_same_device_rejected(self, user: User) -> None:
        DeviceFingerprint.objects.create(user=user, hash="fp-shared")
        referee = self._register_referee(ReferralCode.objects.get(user=user).code, "fp-shared")
        self._complete(referee)
        assert Referral.objects.get(referee=referee).rejected_reason == "same_device"

    def test_cap_35_days(self, user: User) -> None:
        code = ReferralCode.objects.get(user=user).code
        for index in range(6):
            self._complete(self._register_referee(code, f"fp-{index}"))
        total = sum(GrantedDays.objects.filter(user=user).values_list("days", flat=True))
        assert total == 35
        assert Referral.objects.filter(rejected_reason="cap_reached").count() == 1

    def test_overview(self, api: APIClient) -> None:
        body = api.get("/api/v1/me/referral").json()
        assert body["days_cap"] == 35
        assert body["code"] in body["share_url"]


@pytest.mark.django_db
def test_plans_public(reference: None) -> None:
    body = APIClient().get("/api/v1/billing/plans").json()
    codes = [p["code"] for p in body["plans"]]
    assert codes == ["plus_monthly", "plus_annual"]
    annual = body["plans"][1]
    assert annual["savings_percent"] == 13
    assert annual["monthly_equivalent"]["amount_cents"] == 392
