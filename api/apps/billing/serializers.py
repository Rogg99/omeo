"""Entrées et sorties de billing (prix en cents USD, formatés selon la langue)."""

from __future__ import annotations

from typing import Any, Final

from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

from apps.billing import pricing
from apps.billing.models import Payment, Plan, Subscription
from apps.core.i18n import resolve

COMPARISON: Final[list[tuple[str, Any, Any, Any, Any]]] = [
    ("photo_analysis", _("Analyses photo"), "21", _("3 par jour"), _("140 par mois")),
    ("text_analysis", _("Saisie vocale ou texte"), "8", "✖", _("140 par mois")),
    ("full_catalog", _("Exercices et recettes"), _("Tous"), _("Une sélection"), _("Tous")),
    ("challenges_active", _("Challenges en même temps"), "1", "1", _("Sans limite")),
    ("programs", _("Programmes"), "✔", "✖", "✔"),
    ("progress_long_range", _("Progression au-delà de 7 jours"), "✔", "✖", "✔"),
    ("insights", _("Analyses croisées"), "✔", "✖", "✔"),
]


class StorePurchaseSerializer(serializers.Serializer[Any]):
    channel = serializers.ChoiceField(choices=["google_play", "app_store"])
    product_id = serializers.CharField(max_length=120, required=False)
    purchase_token = serializers.CharField(max_length=4096, required=False)
    signed_transaction = serializers.CharField(max_length=20_000, required=False)

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        if attrs["channel"] == "google_play" and not attrs.get("purchase_token"):
            raise serializers.ValidationError({"purchase_token": "required"}, code="required")
        if attrs["channel"] == "app_store" and not attrs.get("signed_transaction"):
            raise serializers.ValidationError({"signed_transaction": "required"}, code="required")
        return attrs


class RestoreSerializer(serializers.Serializer[Any]):
    channel = serializers.ChoiceField(choices=["google_play", "app_store"])
    receipts = serializers.ListField(child=serializers.CharField(max_length=20_000), max_length=50)


class CheckoutSerializer(serializers.Serializer[Any]):
    plan_code = serializers.ChoiceField(choices=["plus_monthly", "plus_annual"])
    promo_code = serializers.CharField(max_length=40, required=False, allow_blank=True)
    success_url = serializers.URLField()
    cancel_url = serializers.URLField()


class PromoCheckSerializer(serializers.Serializer[Any]):
    code = serializers.CharField(max_length=40)
    plan_code = serializers.ChoiceField(choices=["plus_monthly", "plus_annual"])


class PortalSerializer(serializers.Serializer[Any]):
    return_url = serializers.URLField()


def plan_catalog_out(plans: list[Plan], *, locale: str) -> dict[str, Any]:
    monthly = next((p for p in plans if p.interval == "month"), None)
    out = []
    for plan in plans:
        if plan.code in ("trial", "free"):
            continue
        equivalent = pricing.monthly_equivalent(plan.price_cents, plan.interval)
        body: dict[str, Any] = {
            "code": plan.code,
            "name": resolve(plan.name),
            "price": pricing.money(plan.price_cents, locale),
            "interval": plan.interval,
            "featured": plan.is_featured,
            "savings_percent": pricing.savings_percent(annual_cents=plan.price_cents, monthly_cents=monthly.price_cents)
            if monthly and plan.interval == "year"
            else None,
            "store_product_ids": plan.store_product_ids or {},
        }
        if equivalent is not None:
            body["monthly_equivalent"] = pricing.money(equivalent, locale)
        out.append(body)
    comparison = [
        {"feature": f, "label": str(label), "trial": str(trial), "free": str(free), "plus": str(plus)}
        for f, label, trial, free, plus in COMPARISON
    ]
    return {"plans": out, "comparison": comparison}


def subscription_out(subscription: Subscription | None, *, locale: str) -> dict[str, Any] | None:
    if subscription is None:
        return None
    return {
        "plan_code": subscription.plan.code,
        "plan_name": resolve(subscription.plan.name),
        "channel": subscription.channel,
        "status": subscription.status,
        "current_period_end": subscription.current_period_end,
        "auto_renew": subscription.auto_renew,
        "price": pricing.money(subscription.plan.price_cents, locale),
    }


def payment_out(payment: Payment, *, locale: str) -> dict[str, Any]:
    return {
        "id": payment.id,
        "channel": payment.channel,
        "description": payment.description,
        "amount": pricing.money(payment.amount_cents, locale),
        "status": payment.status,
        "paid_at": payment.paid_at,
        "receipt_url": payment.receipt_url or None,
    }
