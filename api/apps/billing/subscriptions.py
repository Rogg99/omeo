"""
Abonnements, achats et paiements : stores (Google Play, App Store), paiement web (agrégateur), codes promo,
webhooks idempotents et jours offerts. L'Entitlement est invalidé à chaque changement.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta
from typing import Any, Final

from django.contrib.auth import get_user_model
from django.db import IntegrityError, transaction
from django.db.models import F, Sum
from django.utils import timezone

from apps.billing import pricing
from apps.billing.models import (
    ENTITLING_STATUSES,
    Channel,
    GrantedDays,
    Payment,
    Plan,
    PromoCode,
    Subscription,
    WebhookEvent,
)
from apps.billing.providers import app_store, google_play
from apps.billing.providers.base import PaymentProvider, VerifiedSubscription
from apps.billing.providers.stripe import StripeProvider
from apps.billing.services import invalidate_entitlement
from apps.core import events, settings_store
from apps.core.errors import Conflict, ValidationFailed

logger = logging.getLogger(__name__)

STORE_CHANNELS: Final = (Channel.GOOGLE_PLAY, Channel.APP_STORE)


def payment_provider() -> PaymentProvider:
    """Agrégateur du paiement web, interchangeable (question ouverte n°3)."""
    return StripeProvider()


# ───────────────────────── Abonnements ─────────────────────────


def _plan_for_product(channel: str, product_id: str) -> Plan:
    for plan in Plan.objects.filter(active=True):
        ids = plan.store_product_ids or {}
        if channel == Channel.GOOGLE_PLAY and ids.get("google") == product_id:
            return plan
        if channel == Channel.APP_STORE and ids.get("apple") == product_id:
            return plan
        if channel == Channel.WEB and plan.web_price_id == product_id:
            return plan
    raise ValidationFailed(errors={"product_id": [{"code": "unknown_product", "message": product_id}]})


@transaction.atomic
def apply_verified(*, user: Any, verified: VerifiedSubscription) -> Subscription:
    """Upsert idempotent. Une notification plus ancienne que la dernière appliquée est ignorée (désordre)."""
    plan = _plan_for_product(verified.channel, verified.product_id)
    subscription = (
        Subscription.objects.select_for_update()
        .filter(channel=verified.channel, external_id=verified.external_id)
        .first()
    )
    if subscription is not None and subscription.user_id != user.pk:
        raise Conflict(code="purchase_owned_elsewhere", detail="purchase linked to another account")
    if subscription is not None and subscription.last_event_at and verified.event_at < subscription.last_event_at:
        return subscription
    values = {
        "plan": plan,
        "status": verified.status,
        "current_period_start": verified.period_start,
        "current_period_end": verified.period_end,
        "auto_renew": verified.auto_renew,
        "raw": {**(subscription.raw if subscription else {}), **verified.raw},
        "last_event_at": verified.event_at,
    }
    if subscription is None:
        subscription = Subscription.objects.create(
            user=user, channel=verified.channel, external_id=verified.external_id, **values
        )
    else:
        for key, value in values.items():
            setattr(subscription, key, value)
        subscription.save()
    transaction.on_commit(lambda: invalidate_entitlement(user.pk))
    events.publish(events.EntitlementChanged(user_id=user.pk))
    return subscription


def active_subscription(user: Any) -> Subscription | None:
    return (
        Subscription.objects.filter(user=user, status__in=ENTITLING_STATUSES, current_period_end__gt=timezone.now())
        .select_related("plan")
        .order_by("-current_period_end")
        .first()
    )


def verify_store_purchase(
    *, user: Any, channel: str, purchase_token: str = "", signed_transaction: str = ""
) -> Subscription:
    if channel == Channel.GOOGLE_PLAY:
        verified = google_play.verify_subscription(purchase_token=purchase_token)
    else:
        transaction_payload = app_store.decode_signed(signed_transaction)
        verified = app_store.subscription_from_transaction(transaction_payload)
    return apply_verified(user=user, verified=verified)


def restore_purchases(*, user: Any, channel: str, receipts: list[str]) -> list[Subscription]:
    restored = []
    for receipt in receipts:
        if channel == Channel.GOOGLE_PLAY:
            restored.append(verify_store_purchase(user=user, channel=channel, purchase_token=receipt))
        else:
            restored.append(verify_store_purchase(user=user, channel=channel, signed_transaction=receipt))
    return restored


# ───────────────────────── Codes promo et paiement web ─────────────────────────


def _usable_promo(code: str, plan: Plan, user: Any) -> PromoCode | None:
    now = timezone.now()
    promo = PromoCode.objects.filter(code__iexact=code.strip(), active=True).prefetch_related("plans").first()
    if promo is None:
        return None
    if (promo.valid_from and promo.valid_from > now) or (promo.valid_until and promo.valid_until < now):
        return None
    if promo.max_redemptions is not None and promo.redeemed_count >= promo.max_redemptions:
        return None
    plans = list(promo.plans.all())
    if plans and plan not in plans:
        return None
    if promo.redemptions.filter(user=user).exists():
        return None
    return promo


def _web_plan(plan_code: str) -> Plan:
    plan = Plan.objects.filter(code=plan_code, active=True).exclude(web_price_id="").first()
    if plan is None:
        raise ValidationFailed(errors={"plan_code": [{"code": "unavailable", "message": plan_code}]})
    return plan


def check_promo(*, user: Any, code: str, plan_code: str, locale: str) -> dict[str, Any]:
    plan = _web_plan(plan_code)
    promo = _usable_promo(code, plan, user)
    if promo is None:
        return {"valid": False}
    discounted = pricing.apply_discount(plan.price_cents, pricing.Discount(kind=promo.kind, value=promo.value))
    label = f"-{promo.value} %" if promo.kind == "percent" else pricing.format_usd(-promo.value, locale)
    if promo.kind == "free_days":
        label = f"+{promo.value} j"
    return {
        "valid": True,
        "label": label,
        "original": pricing.money(plan.price_cents, locale),
        "discounted": pricing.money(discounted, locale),
    }


def create_checkout(
    *, user: Any, plan_code: str, promo_code: str | None, success_url: str, cancel_url: str, idempotency_key: str
) -> Any:
    store = active_subscription(user)
    if store is not None and store.channel in STORE_CHANNELS:
        raise Conflict(code="store_subscription_active", detail="manage the subscription in the store")
    plan = _web_plan(plan_code)
    promo = _usable_promo(promo_code, plan, user) if promo_code else None
    if promo_code and promo is None:
        raise ValidationFailed(errors={"promo_code": [{"code": "invalid", "message": "invalid promo code"}]})
    percent_off = promo.value if promo and promo.kind == "percent" else 0
    amount_off = promo.value if promo and promo.kind == "amount" else 0
    session = payment_provider().create_checkout(
        user_id=str(user.pk),
        email=user.email,
        price_id=plan.web_price_id,
        amount_off_cents=amount_off,
        percent_off=percent_off,
        success_url=success_url,
        cancel_url=cancel_url,
        idempotency_key=idempotency_key,
    )
    if promo is not None:
        with transaction.atomic():
            try:
                promo.redemptions.create(user=user)
            except IntegrityError:
                raise ValidationFailed(errors={"promo_code": [{"code": "used", "message": "already used"}]}) from None
            PromoCode.objects.filter(pk=promo.pk).update(redeemed_count=F("redeemed_count") + 1)
    return session


def create_portal(*, user: Any, return_url: str) -> str:
    subscription = Subscription.objects.filter(user=user, channel=Channel.WEB).order_by("-current_period_end").first()
    customer = (subscription.raw or {}).get("customer") if subscription else None
    if not customer:
        raise Conflict(code="no_web_subscription", detail="no web subscription")
    return payment_provider().create_portal(customer_id=str(customer), return_url=return_url)


# ───────────────────────── Webhooks (idempotents) ─────────────────────────


@transaction.atomic
def _record_event(*, provider: str, event_id: str, type_: str, payload: dict[str, Any], occurred_at: datetime) -> bool:
    """Vrai si l'événement est nouveau (sinon : déjà traité, on ne fait rien)."""
    try:
        with transaction.atomic():
            WebhookEvent.objects.create(
                provider=provider, event_id=event_id, type=type_, payload=payload, occurred_at=occurred_at
            )
    except IntegrityError:
        return False
    return True


def _mark_processed(provider: str, event_id: str) -> None:
    WebhookEvent.objects.filter(provider=provider, event_id=event_id).update(processed_at=timezone.now())


def _user_for(channel: str, external_id: str) -> Any:
    subscription = Subscription.objects.filter(channel=channel, external_id=external_id).select_related("user").first()
    return subscription.user if subscription else None


@transaction.atomic
def handle_google_play(*, body: dict[str, Any], authorization: str) -> None:
    google_play.verify_push_token(authorization)
    message_id, published_at, notification = google_play.parse_push(body)
    if not _record_event(
        provider="google_play", event_id=message_id, type_="rtdn", payload=notification, occurred_at=published_at
    ):
        return
    token = (notification.get("subscriptionNotification") or {}).get("purchaseToken")
    user = _user_for(Channel.GOOGLE_PLAY, token) if token else None
    if user is not None:
        apply_verified(user=user, verified=google_play.verify_subscription(purchase_token=token))
    _mark_processed("google_play", message_id)


@transaction.atomic
def handle_app_store(*, signed_payload: str) -> None:
    notification_id, signed_at, notification_type, verified = app_store.parse_notification(signed_payload)
    if not _record_event(
        provider="app_store",
        event_id=notification_id,
        type_=notification_type,
        payload={"notificationType": notification_type},
        occurred_at=signed_at,
    ):
        return
    if verified is not None:
        user = _user_for(Channel.APP_STORE, verified.external_id)
        if user is not None:
            apply_verified(user=user, verified=verified)
    _mark_processed("app_store", notification_id)


def _payment_from_event(user: Any, payment: dict[str, Any], status: str) -> None:
    subscription = (
        Subscription.objects.filter(channel=Channel.WEB, external_id=payment.get("subscription_external_id")).first()
        if payment.get("subscription_external_id")
        else None
    )
    Payment.objects.update_or_create(
        external_id=payment["external_id"],
        defaults={
            "user": user,
            "subscription": subscription,
            "channel": Channel.WEB,
            "amount_cents": payment.get("amount_cents", 0),
            "status": status,
            "paid_at": payment.get("paid_at") or timezone.now(),
            "receipt_url": payment.get("receipt_url", ""),
        },
    )


@transaction.atomic
def handle_payments(*, body: bytes, headers: dict[str, str]) -> None:
    event = payment_provider().parse_webhook(body=body, headers=headers)
    if not _record_event(
        provider="payments", event_id=event.event_id, type_=event.type, payload=event.raw, occurred_at=event.occurred_at
    ):
        return
    user = get_user_model().objects.filter(pk=event.user_id).first() if event.user_id else None
    payment = event.payment or {}
    if event.type == "subscription_updated" and user is not None and event.subscription is not None:
        apply_verified(user=user, verified=event.subscription)
    elif event.type in ("payment_succeeded", "payment_failed") and user is not None:
        _payment_from_event(user, payment, "succeeded" if event.type == "payment_succeeded" else "failed")
    elif event.type == "refunded":
        Payment.objects.filter(external_id=payment.get("external_id")).update(status="refunded")
    _mark_processed("payments", event.event_id)


# ───────────────────────── Jours offerts ─────────────────────────


@transaction.atomic
def grant_days(*, user: Any, days: int, reason: str, ref_id: str = "", created_by: Any = None) -> GrantedDays | None:
    """Ajoute des jours de Plus à la suite des droits existants. Le parrainage est plafonné (35 jours)."""
    if reason == "referral":
        cap = int(settings_store.get("referral.cap_days", 35))
        already = GrantedDays.objects.filter(user=user, reason="referral").aggregate(total=Sum("days"))["total"] or 0
        days = min(days, cap - already)
        if days <= 0:
            return None
    now = timezone.now()
    granted_ends = GrantedDays.objects.filter(user=user, ends_at__gt=now).values_list("ends_at", flat=True)
    subscription_ends = Subscription.objects.filter(
        user=user, status__in=ENTITLING_STATUSES, current_period_end__gt=now
    ).values_list("current_period_end", flat=True)
    latest_end = max([now, *granted_ends, *subscription_ends])
    grant = GrantedDays.objects.create(
        user=user,
        days=days,
        reason=reason,
        ref_id=ref_id,
        starts_at=latest_end,
        ends_at=latest_end + timedelta(days=days),
        created_by=created_by,
    )
    transaction.on_commit(lambda: invalidate_entitlement(user.pk))
    return grant
