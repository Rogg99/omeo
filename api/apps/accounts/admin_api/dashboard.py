"""
Tableau de bord du back-office. Les indicateurs financiers et du support ne sont renvoyés qu'aux personnes ayant
`dashboard.finance` ou `dashboard.support` ; les autres reçoivent `null`.
"""

from __future__ import annotations

from datetime import date, timedelta
from typing import Any

from django.db.models import Count, Q, QuerySet, Sum
from django.db.models.functions import TruncDate
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from apps.accounts.models import User
from apps.billing import pricing
from apps.billing.models import ENTITLING_STATUSES, Payment, Subscription, Trial
from apps.core import access
from apps.core.views import AdminAPIView, validated
from apps.meals.models import Analysis, AnalysisFeedback
from apps.support.models import Ticket

MONTHS_PER_YEAR = 12


class DashboardFilterSerializer(serializers.Serializer[Any]):
    to = serializers.DateField()
    country = serializers.CharField(max_length=2, required=False)
    locale = serializers.CharField(max_length=2, required=False)
    platform = serializers.ChoiceField(choices=["android", "ios", "web"], required=False)

    def to_internal_value(self, data: Any) -> Any:
        values = super().to_internal_value(data)
        values["from"] = serializers.DateField().to_internal_value(data.get("from"))
        return values


def _series(queryset: QuerySet[Any], field: str, start: date, end: date) -> dict[str, Any]:
    rows = (
        queryset.filter(**{f"{field}__date__gte": start, f"{field}__date__lte": end})
        .annotate(day=TruncDate(field))
        .values("day")
        .annotate(value=Count("id"))
        .order_by("day")
    )
    series = [{"date": row["day"], "value": row["value"]} for row in rows]
    total = sum(point["value"] for point in series)
    span = (end - start).days + 1
    previous = queryset.filter(
        **{f"{field}__date__gte": start - timedelta(days=span), f"{field}__date__lt": start}
    ).count()
    delta = round((total - previous) / previous * 100, 1) if previous else None
    return {"total": total, "delta_percent": delta, "series": series}


def _users(params: dict[str, Any]) -> QuerySet[User]:
    users = User.objects.filter(is_staff=False)
    if params.get("country"):
        users = users.filter(profile__country=params["country"].upper())
    if params.get("locale"):
        users = users.filter(locale=params["locale"])
    if params.get("platform"):
        users = users.filter(sessions__platform=params["platform"]).distinct()
    return users


def _retention(users: QuerySet[User], days: int) -> float | None:
    cohort = users.filter(created_at__lte=timezone.now() - timedelta(days=days))
    size = cohort.count()
    if not size:
        return None
    retained = cohort.filter(last_seen_at__gte=timezone.now() - timedelta(days=1)).count()
    return round(retained / size, 3)


def _finance(start: date, end: date) -> dict[str, Any]:
    payments = Payment.objects.filter(status="succeeded", paid_at__date__gte=start, paid_at__date__lte=end)
    by_channel = payments.values("channel").annotate(total=Sum("amount_cents")).order_by("channel")
    mrr_cents = 0
    for subscription in Subscription.objects.filter(
        status__in=ENTITLING_STATUSES, current_period_end__gt=timezone.now()
    ).select_related("plan"):
        price = subscription.plan.price_cents
        mrr_cents += price // MONTHS_PER_YEAR if subscription.plan.interval == "year" else price
    ai_micros = Analysis.objects.filter(created_at__date__gte=start, created_at__date__lte=end).aggregate(
        total=Sum("cost_usd_micros")
    )["total"]
    trials = Trial.objects.filter(ends_at__date__gte=start, ends_at__date__lte=end)
    converted = trials.filter(user__subscriptions__isnull=False).distinct().count()
    return {
        "revenue_by_channel": [
            {"channel": row["channel"], "amount": pricing.money(int(row["total"] or 0), "fr")} for row in by_channel
        ],
        "mrr": pricing.money(mrr_cents, "fr"),
        "ai_cost": pricing.money(int((ai_micros or 0) / 10_000), "fr"),
        "trial_to_plus_rate": round(converted / trials.count(), 3) if trials.exists() else None,
    }


class DashboardView(AdminAPIView):
    required_permission = "dashboard.product"

    @extend_schema(operation_id="adminDashboard")
    def get(self, request: Request) -> Response:
        params = validated(DashboardFilterSerializer, request.query_params)
        start, end = params["from"], params["to"]
        users = _users(params)
        now = timezone.now()
        feedback = AnalysisFeedback.objects.filter(created_at__date__gte=start, created_at__date__lte=end)
        totals = feedback.aggregate(total=Count("id"), negatives=Count("id", filter=Q(rating="down")))
        permissions = access.permissions_for_user(request.user)
        body: dict[str, Any] = {
            "signups": _series(users, "created_at", start, end),
            "active_users": {
                "dau": users.filter(last_seen_at__gte=now - timedelta(days=1)).count(),
                "wau": users.filter(last_seen_at__gte=now - timedelta(days=7)).count(),
                "mau": users.filter(last_seen_at__gte=now - timedelta(days=30)).count(),
            },
            "retention": {"d1": _retention(users, 1), "d7": _retention(users, 7), "d30": _retention(users, 30)},
            "analyses": _series(Analysis.objects.filter(user__in=users), "created_at", start, end),
            "negative_feedback_rate": round(totals["negatives"] / totals["total"], 3) if totals["total"] else None,
            "trial_to_plus_rate": None,
            "revenue_by_channel": None,
            "mrr": None,
            "ai_cost": None,
            "support_pending": None,
        }
        if "dashboard.finance" in permissions:
            body.update(_finance(start, end))
        if "dashboard.support" in permissions:
            body["support_pending"] = Ticket.objects.filter(status__in=["new", "open"]).count()
        return Response(body)
