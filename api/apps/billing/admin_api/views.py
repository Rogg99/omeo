"""Back-office billing : offres et quotas (quatre yeux), abonnements, paiements et remboursements, codes promo."""

from __future__ import annotations

from decimal import Decimal
from typing import Any, ClassVar

from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.permissions import BasePermission, IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from apps.billing import admin_services, pricing
from apps.billing.models import Payment, Plan, PromoCode, QuotaRule, Subscription
from apps.core import settings_store
from apps.core.approvals import ApprovalService, is_enabled
from apps.core.errors import Conflict, NotFound, ValidationFailed
from apps.core.i18n import validate_i18n_text
from apps.core.models import ApprovalKind
from apps.core.pagination import page_body, page_paginate
from apps.core.permissions import HasPermission, RequiresStepUp
from apps.core.presenters import approval_out
from apps.core.views import AdminAPIView, validated


class PlanUpdateSerializer(serializers.Serializer[Any]):
    name = serializers.JSONField(required=False, validators=[validate_i18n_text])
    price_cents = serializers.IntegerField(min_value=0, required=False)
    interval = serializers.ChoiceField(choices=["month", "year", "none"], required=False)
    is_featured = serializers.BooleanField(required=False)
    store_product_ids = serializers.DictField(child=serializers.CharField(max_length=120), required=False)
    web_price_id = serializers.CharField(max_length=120, required=False, allow_null=True, allow_blank=True)
    active = serializers.BooleanField(required=False)
    reason = serializers.CharField(min_length=3, max_length=500, required=False, default="Modification d'offre")


class PlansView(AdminAPIView):
    required_permission = "billing.view"

    @extend_schema(operation_id="adminListPlans")
    def get(self, request: Request) -> Response:
        return Response([admin_services.plan_out(p) for p in Plan.objects.order_by("price_cents")])


def _submit(
    request: Request,
    *,
    kind: str,
    domain: str,
    payload: dict[str, Any],
    before: Any,
    target_type: str,
    target_id: str,
    reason: str,
) -> Response | None:
    """Crée la demande à quatre yeux (202), ou None si la validation est désactivée pour ce domaine."""
    if not is_enabled(domain):
        return None
    approval = ApprovalService.create(
        kind=kind,
        payload=payload,
        diff={"before": before, "after": payload},
        target_type=target_type,
        target_id=target_id,
        reason=reason,
        requested_by=request.user,
        request=request,
    )
    return Response(approval_out(approval), status=status.HTTP_202_ACCEPTED)


class PlanDetailView(AdminAPIView):
    required_permission = "billing.plans_edit"

    @extend_schema(operation_id="adminUpdatePlan", request=PlanUpdateSerializer)
    def patch(self, request: Request, code: str) -> Response:
        plan = Plan.objects.filter(code=code).first()
        if plan is None:
            raise NotFound()
        data = validated(PlanUpdateSerializer, request.data)
        reason = data.pop("reason")
        pending = _submit(
            request,
            kind=ApprovalKind.PLAN_UPDATE,
            domain="finance",
            payload={"code": code, "changes": data},
            before=admin_services.plan_out(plan),
            target_type="plan",
            target_id=code,
            reason=reason,
        )
        if pending is not None:
            return pending
        admin_services.apply_plan_update_payload({"code": code, "changes": data})
        return Response(admin_services.plan_out(Plan.objects.get(code=code)))


class QuotaRuleSerializer(serializers.Serializer[Any]):
    plan_tier = serializers.ChoiceField(choices=["trial", "free", "plus"])
    feature = serializers.ChoiceField(choices=["photo_analysis", "text_analysis", "challenges_active"])
    limit = serializers.IntegerField(min_value=0, allow_null=True)
    period = serializers.ChoiceField(choices=["day", "month", "trial"])


def quota_out(rule: QuotaRule) -> dict[str, Any]:
    return {"plan_tier": rule.plan_tier, "feature": rule.feature, "limit": rule.limit, "period": rule.period}


class QuotasView(AdminAPIView):
    permission_map: ClassVar[dict[str, str] | None] = {"GET": "billing.view", "PUT": "billing.quotas_edit"}

    @extend_schema(operation_id="adminListQuotaRules")
    def get(self, request: Request) -> Response:
        return Response([quota_out(r) for r in QuotaRule.objects.order_by("plan_tier", "feature")])

    @extend_schema(operation_id="adminReplaceQuotaRules", request=QuotaRuleSerializer(many=True))
    def put(self, request: Request) -> Response:
        serializer = QuotaRuleSerializer(data=request.data, many=True)
        serializer.is_valid(raise_exception=True)
        rules = [dict(r) for r in serializer.validated_data]
        pending = _submit(
            request,
            kind=ApprovalKind.QUOTA_UPDATE,
            domain="finance",
            payload={"rules": rules},
            before=[quota_out(r) for r in QuotaRule.objects.all()],
            target_type="quota_rules",
            target_id="all",
            reason="Modification des quotas",
        )
        if pending is not None:
            return pending
        admin_services.apply_quota_rules_payload({"rules": rules})
        return Response([quota_out(r) for r in QuotaRule.objects.order_by("plan_tier", "feature")])


class SubscriptionsView(AdminAPIView):
    required_permission = "billing.view"

    @extend_schema(operation_id="adminListSubscriptions")
    def get(self, request: Request) -> Response:
        queryset = Subscription.objects.select_related("user", "plan").order_by("-created_at")
        for field in ("status", "channel"):
            if request.query_params.get(field):
                queryset = queryset.filter(**{field: request.query_params[field]})
        if request.query_params.get("q"):
            queryset = queryset.filter(user__email__icontains=request.query_params["q"])
        rows, meta = page_paginate(request, queryset)
        return Response(
            page_body(
                [
                    {
                        "id": s.id,
                        "user_id": s.user_id,
                        "user_email": s.user.email,
                        "plan_code": s.plan.code,
                        "channel": s.channel,
                        "status": s.status,
                        "current_period_end": s.current_period_end,
                        "auto_renew": s.auto_renew,
                        "created_at": s.created_at,
                    }
                    for s in rows
                ],
                meta,
            )
        )


def payment_row_out(payment: Payment, *, locale: str) -> dict[str, Any]:
    refunded = sum(r.amount_cents for r in payment.refunds.all())
    return {
        "id": payment.id,
        "channel": payment.channel,
        "description": payment.description,
        "amount": pricing.money(payment.amount_cents, locale),
        "status": payment.status,
        "paid_at": payment.paid_at,
        "receipt_url": payment.receipt_url or None,
        "user_id": payment.user_id,
        "user_email": payment.user.email,
        "external_id": payment.external_id,
        "refundable": payment.channel == "web" and payment.status == "succeeded" and refunded < payment.amount_cents,
        "refunded": pricing.money(refunded, locale) if refunded else None,
    }


class PaymentsView(AdminAPIView):
    required_permission = "billing.view"

    @extend_schema(operation_id="adminListPayments")
    def get(self, request: Request) -> Response:
        queryset = Payment.objects.select_related("user").prefetch_related("refunds").order_by("-paid_at")
        for field in ("status", "channel"):
            if request.query_params.get(field):
                queryset = queryset.filter(**{field: request.query_params[field]})
        rows, meta = page_paginate(request, queryset)
        return Response(page_body([payment_row_out(p, locale="fr") for p in rows], meta))


class RefundSerializer(serializers.Serializer[Any]):
    amount_cents = serializers.IntegerField(min_value=1, required=False)
    confirm = serializers.CharField(max_length=254, required=False, allow_blank=True)
    reason = serializers.CharField(min_length=3, max_length=500)


class RefundView(AdminAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, HasPermission, RequiresStepUp]
    required_permission = "billing.refund"

    @extend_schema(operation_id="adminRefundPayment", request=RefundSerializer)
    def post(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        data = validated(RefundSerializer, request.data)
        payment = Payment.objects.select_related("user").prefetch_related("refunds").filter(pk=id).first()
        if payment is None:
            raise NotFound()
        remaining = payment.amount_cents - sum(r.amount_cents for r in payment.refunds.all())
        amount = data.get("amount_cents") or remaining
        if payment.channel != "web" or payment.status != "succeeded" or not 0 < amount <= remaining:
            raise Conflict(code="not_refundable", detail="payment not refundable")
        if amount == payment.amount_cents and (data.get("confirm") or "").strip().lower() != payment.user.email:
            raise ValidationFailed(
                errors={"confirm": [{"code": "confirmation_required", "message": "type the user email"}]}
            )
        threshold = Decimal(str(settings_store.get("billing.refund_approval_threshold_usd", 50))) * 100
        payload = {"payment_id": str(payment.pk), "amount_cents": amount, "reason": data["reason"]}
        if amount > threshold:
            pending = _submit(
                request,
                kind=ApprovalKind.REFUND,
                domain="finance",
                payload=payload,
                before={"refunded_cents": payment.amount_cents - remaining},
                target_type="payment",
                target_id=str(payment.pk),
                reason=data["reason"],
            )
            if pending is not None:
                return pending
        admin_services.execute_refund(payload, actor=request.user, request=request)
        return Response(
            payment_row_out(Payment.objects.prefetch_related("refunds").select_related("user").get(pk=id), locale="fr")
        )


class PromoSerializer(serializers.Serializer[Any]):
    code = serializers.RegexField(r"^[A-Z0-9_-]{3,40}$")
    kind = serializers.ChoiceField(choices=["percent", "amount", "free_days"])
    value = serializers.IntegerField(min_value=0)
    plan_codes = serializers.ListField(child=serializers.CharField(max_length=24), required=False, default=list)
    max_redemptions = serializers.IntegerField(min_value=1, required=False, allow_null=True)
    valid_from = serializers.DateTimeField()
    valid_until = serializers.DateTimeField(required=False, allow_null=True)
    active = serializers.BooleanField(required=False, default=True)


def promo_out(promo: PromoCode) -> dict[str, Any]:
    return {
        "id": promo.id,
        "code": promo.code,
        "kind": promo.kind,
        "value": promo.value,
        "plan_codes": [p.code for p in promo.plans.all()],
        "max_redemptions": promo.max_redemptions,
        "redeemed_count": promo.redeemed_count,
        "valid_from": promo.valid_from,
        "valid_until": promo.valid_until,
        "active": promo.active,
    }


class PromoCodesView(AdminAPIView):
    permission_map: ClassVar[dict[str, str] | None] = {"GET": "billing.view", "POST": "billing.promo_manage"}

    @extend_schema(operation_id="adminListPromoCodes")
    def get(self, request: Request) -> Response:
        rows, meta = page_paginate(request, PromoCode.objects.prefetch_related("plans").order_by("-created_at"))
        return Response(page_body([promo_out(p) for p in rows], meta))

    @extend_schema(operation_id="adminCreatePromoCode", request=PromoSerializer)
    def post(self, request: Request) -> Response:
        data = validated(PromoSerializer, request.data)
        if PromoCode.objects.filter(code=data["code"]).exists():
            raise Conflict(code="promo_exists", detail="code already exists")
        promo = admin_services.save_promo(PromoCode(), data, actor=request.user, request=request)
        return Response(promo_out(promo), status=status.HTTP_201_CREATED)


class PromoCodeDetailView(AdminAPIView):
    required_permission = "billing.promo_manage"

    @extend_schema(operation_id="adminUpdatePromoCode", request=PromoSerializer)
    def patch(self, request: Request, id: Any) -> Response:  # noqa: A002
        promo = PromoCode.objects.filter(pk=id).first()
        if promo is None:
            raise NotFound()
        data = validated(PromoSerializer, request.data, partial=True)
        return Response(promo_out(admin_services.save_promo(promo, data, actor=request.user, request=request)))
