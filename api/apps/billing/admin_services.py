"""Écritures du back-office billing : exécuteurs des validations à quatre yeux, remboursements, codes promo."""

from __future__ import annotations

from typing import Any

from django.db import transaction

from apps.billing.models import Payment, Plan, PromoCode, QuotaRule, Refund
from apps.billing.services import invalidate_quota_rules
from apps.billing.subscriptions import payment_provider
from apps.core import audit
from apps.core.models import ApprovalRequest


def plan_out(plan: Plan) -> dict[str, Any]:
    return {
        "code": plan.code,
        "name": plan.name,
        "price_cents": plan.price_cents,
        "interval": plan.interval,
        "is_featured": plan.is_featured,
        "store_product_ids": plan.store_product_ids,
        "web_price_id": plan.web_price_id or None,
        "active": plan.active,
    }


def apply_plan_update_payload(payload: dict[str, Any]) -> dict[str, Any]:
    plan = Plan.objects.select_for_update().get(code=payload["code"])
    for key, value in payload["changes"].items():
        setattr(plan, key, value if value is not None else "")
    plan.save()
    return plan_out(plan)


def apply_plan_update(approval: ApprovalRequest, decider: Any) -> dict[str, Any]:
    return apply_plan_update_payload(approval.payload)


def apply_quota_rules_payload(payload: dict[str, Any]) -> dict[str, Any]:
    for rule in payload["rules"]:
        QuotaRule.objects.update_or_create(
            plan_tier=rule["plan_tier"],
            feature=rule["feature"],
            defaults={"limit": rule["limit"], "period": rule["period"]},
        )
    transaction.on_commit(invalidate_quota_rules)
    return {"rules": payload["rules"]}


def apply_quota_update(approval: ApprovalRequest, decider: Any) -> dict[str, Any]:
    return apply_quota_rules_payload(approval.payload)


@transaction.atomic
def execute_refund(payload: dict[str, Any], *, actor: Any, request: Any = None) -> dict[str, Any]:
    payment = Payment.objects.select_for_update().get(pk=payload["payment_id"])
    external = payment_provider().refund(
        payment_external_id=payment.external_id,
        amount_cents=payload["amount_cents"],
        idempotency_key=f"refund-{payment.pk}-{payload['amount_cents']}",
    )
    Refund.objects.create(
        payment=payment,
        amount_cents=payload["amount_cents"],
        reason=payload["reason"],
        created_by=actor,
        external_id=external,
    )
    if sum(payment.refunds.values_list("amount_cents", flat=True)) >= payment.amount_cents:
        payment.status = "refunded"
        payment.save(update_fields=["status", "updated_at"])
    audit.record(
        actor=actor,
        action="billing.refund",
        target_type="payment",
        target_id=payment.pk,
        after={"amount_cents": payload["amount_cents"]},
        reason=payload["reason"],
        request=request,
    )
    return {"refund_external_id": external}


def apply_refund(approval: ApprovalRequest, decider: Any) -> dict[str, Any]:
    return execute_refund(approval.payload, actor=decider)


def save_promo(promo: PromoCode, data: dict[str, Any], *, actor: Any, request: Any) -> PromoCode:
    plan_codes = data.pop("plan_codes", None)
    for key, value in data.items():
        setattr(promo, key, value)
    promo.save()
    if plan_codes is not None:
        promo.plans.set(Plan.objects.filter(code__in=plan_codes))
    audit.record(
        actor=actor,
        action="billing.promo",
        target_type="promo",
        target_id=promo.pk,
        after={"code": promo.code},
        request=request,
    )
    return promo
