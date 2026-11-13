"""Vues minces de billing : offres, abonnement, achats stores, paiement web, parrainage, webhooks."""

from __future__ import annotations

from typing import ClassVar

from django.conf import settings
from django.utils.translation import gettext as _
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import BasePermission, IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.throttling import BaseThrottle

from apps.accounts.models import Referral, ReferralCode
from apps.billing import serializers as s
from apps.billing import subscriptions
from apps.billing.models import Payment, Plan
from apps.billing.presenters import subscription_state
from apps.billing.providers.base import InvalidSignatureError
from apps.core import settings_store
from apps.core.errors import NotAuthenticated
from apps.core.i18n import active_locale
from apps.core.idempotency import idempotent
from apps.core.pagination import cursor_body, cursor_paginate
from apps.core.permissions import RequiresVerifiedEmail
from apps.core.throttles import PublicReadThrottle
from apps.core.views import AppAPIView, PublicAPIView, validated


class PlansView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [PublicReadThrottle]

    @extend_schema(operation_id="listPlans")
    def get(self, request: Request) -> Response:
        plans = list(Plan.objects.filter(active=True).order_by("price_cents"))
        return Response(s.plan_catalog_out(plans, locale=active_locale()))


class SubscriptionView(AppAPIView):
    @extend_schema(operation_id="getSubscription")
    def get(self, request: Request) -> Response:
        return Response(subscription_state(request.user))


class VerifyPurchaseView(AppAPIView):
    @extend_schema(operation_id="verifyStorePurchase", request=s.StorePurchaseSerializer)
    @idempotent
    def post(self, request: Request) -> Response:
        data = validated(s.StorePurchaseSerializer, request.data)
        subscriptions.verify_store_purchase(
            user=request.user,
            channel=data["channel"],
            purchase_token=data.get("purchase_token", ""),
            signed_transaction=data.get("signed_transaction", ""),
        )
        return Response(subscription_state(request.user))


class RestoreView(AppAPIView):
    @extend_schema(operation_id="restorePurchases", request=s.RestoreSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.RestoreSerializer, request.data)
        subscriptions.restore_purchases(user=request.user, channel=data["channel"], receipts=data["receipts"])
        return Response(subscription_state(request.user))


class PaymentsView(AppAPIView):
    @extend_schema(operation_id="listPayments")
    def get(self, request: Request) -> Response:
        rows, next_cursor = cursor_paginate(request, Payment.objects.filter(user=request.user), order_field="paid_at")
        locale = active_locale()
        return Response(cursor_body([s.payment_out(p, locale=locale) for p in rows], next_cursor))


class CheckoutView(AppAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, RequiresVerifiedEmail]

    @extend_schema(operation_id="createWebCheckout", request=s.CheckoutSerializer)
    @idempotent
    def post(self, request: Request) -> Response:
        data = validated(s.CheckoutSerializer, request.data)
        session = subscriptions.create_checkout(
            user=request.user,
            plan_code=data["plan_code"],
            promo_code=data.get("promo_code") or None,
            success_url=data["success_url"],
            cancel_url=data["cancel_url"],
            idempotency_key=str(request.META.get("HTTP_IDEMPOTENCY_KEY")),
        )
        return Response({"checkout_url": session.url, "expires_at": session.expires_at}, status=status.HTTP_201_CREATED)


class PromoCheckView(AppAPIView):
    @extend_schema(operation_id="checkPromoCode", request=s.PromoCheckSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.PromoCheckSerializer, request.data)
        return Response(
            subscriptions.check_promo(
                user=request.user, code=data["code"], plan_code=data["plan_code"], locale=active_locale()
            )
        )


class PortalView(AppAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, RequiresVerifiedEmail]

    @extend_schema(operation_id="createBillingPortal", request=s.PortalSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.PortalSerializer, request.data)
        url = subscriptions.create_portal(user=request.user, return_url=data["return_url"])
        return Response({"url": url}, status=status.HTTP_201_CREATED)


class ReferralView(AppAPIView):
    @extend_schema(operation_id="getReferral")
    def get(self, request: Request) -> Response:
        user = request.user
        code = ReferralCode.objects.filter(user=user).first()
        referrals = list(
            Referral.objects.filter(referrer=user).select_related("referee__profile").order_by("-created_at")
        )
        share_url = f"{settings.WEB_BASE_URL.rstrip('/')}/invite/{code.code if code else ''}"
        first_name = user.profile.first_name
        return Response(
            {
                "code": code.code if code else "",
                "share_url": share_url,
                "share_message": _(
                    "%(name)s t'invite sur Omeo : 7 jours d'essai offerts avec le code %(code)s. %(url)s"
                )
                % {"name": first_name, "code": code.code if code else "", "url": share_url},
                "validated_count": sum(1 for r in referrals if r.status == "validated"),
                "pending_count": sum(1 for r in referrals if r.status == "pending"),
                "days_earned": sum(r.reward_days for r in referrals),
                "days_cap": int(settings_store.get("referral.cap_days", 35)),
                "referees": [
                    {"first_name": r.referee.profile.first_name, "status": r.status, "date": r.created_at.date()}
                    for r in referrals
                ],
            }
        )


class GooglePlayWebhookView(PublicAPIView):
    @extend_schema(operation_id="googlePlayRtdn")
    def post(self, request: Request) -> Response:
        try:
            subscriptions.handle_google_play(body=request.data, authorization=request.headers.get("Authorization", ""))
        except InvalidSignatureError:
            raise NotAuthenticated() from None
        return Response(status=status.HTTP_204_NO_CONTENT)


class AppStoreWebhookView(PublicAPIView):
    @extend_schema(operation_id="appStoreNotification")
    def post(self, request: Request) -> Response:
        signed = request.data.get("signedPayload", "") if isinstance(request.data, dict) else ""
        try:
            subscriptions.handle_app_store(signed_payload=str(signed))
        except InvalidSignatureError:
            raise NotAuthenticated() from None
        return Response(status=status.HTTP_204_NO_CONTENT)


class PaymentsWebhookView(PublicAPIView):
    @extend_schema(operation_id="paymentProviderWebhook")
    def post(self, request: Request) -> Response:
        headers = {k.lower(): v for k, v in request.headers.items()}
        try:
            subscriptions.handle_payments(body=request.body, headers=headers)
        except InvalidSignatureError:
            raise NotAuthenticated() from None
        return Response(status=status.HTTP_204_NO_CONTENT)
