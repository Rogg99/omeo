"""Lectures des notifications et ciblage des campagnes."""

from __future__ import annotations

from datetime import timedelta
from typing import Any

from django.db.models import OuterRef, Q, QuerySet, Subquery
from django.utils import timezone

from apps.accounts.models import Consent, User
from apps.billing.services import entitlement_for
from apps.notifications.models import Notification


def notifications_for(*, user: Any, unread: bool | None) -> QuerySet[Notification]:
    queryset = Notification.objects.filter(user=user)
    if unread:
        queryset = queryset.filter(read_at__isnull=True)
    return queryset


def campaign_audience(segment: dict[str, Any]) -> QuerySet[User]:
    """Comptes ciblés : consentement marketing (dernier enregistrement accordé), puis filtres du segment."""
    latest_marketing = Consent.objects.filter(user=OuterRef("pk"), kind="marketing").order_by("-created_at")
    queryset = (
        User.objects.filter(is_active=True, is_staff=False, deletion_scheduled_at__isnull=True)
        .annotate(marketing=Subquery(latest_marketing.values("granted")[:1]))
        .filter(marketing=True)
    )
    if segment.get("locales"):
        queryset = queryset.filter(locale__in=segment["locales"])
    if segment.get("countries"):
        queryset = queryset.filter(profile__country__in=segment["countries"])
    if segment.get("goals"):
        queryset = queryset.filter(profile__goals__overlap=segment["goals"])
    if segment.get("inactive_days"):
        threshold = timezone.now() - timedelta(days=int(segment["inactive_days"]))
        queryset = queryset.filter(Q(last_seen_at__lt=threshold) | Q(last_seen_at__isnull=True))
    return queryset.select_related("profile")


def filter_by_tier(users: QuerySet[User], tiers: list[str] | None) -> list[User]:
    if not tiers:
        return list(users)
    return [user for user in users.iterator() if entitlement_for(user).tier in tiers]
