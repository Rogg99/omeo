"""Tâches Celery des notifications (idempotentes : une notification par clé de déduplication)."""

from __future__ import annotations

from celery import shared_task
from django.db import transaction
from django.db.models import F
from django.utils import timezone

from apps.accounts.models import User
from apps.core.localtime import local_today
from apps.meals.models import Meal
from apps.notifications import selectors, services
from apps.notifications.models import Campaign, CampaignStatus
from apps.nutrition.models import DailySummary


@shared_task(name=services.SEND_PUSH_TASK, acks_late=True, ignore_result=True, max_retries=3)
def send_push(notification_id: str) -> None:
    services.send_push(notification_id=notification_id)


@shared_task(acks_late=True, ignore_result=True)
def send_reminders() -> int:
    """Toutes les 15 minutes : rappels de repas, d'hydratation et de pesée dus à l'heure locale de chacun."""
    sent = 0
    for user in User.objects.filter(is_active=True, is_staff=False).select_related("profile").iterator():
        today = local_today(user)
        logged = set(Meal.objects.filter(user=user, date=today).values_list("meal_type", flat=True))
        summary = DailySummary.objects.filter(user=user, date=today).only("water_ml", "target_water_ml").first()
        sent += services.send_due_reminders(
            user=user,
            logged_meal_types=logged,
            water_ml=summary.water_ml if summary else 0,
            water_target=summary.target_water_ml if summary else 0,
        )
    return sent


@shared_task(acks_late=True, ignore_result=True)
def send_campaigns() -> int:
    """Envoie les campagnes programmées échues. Idempotent : une notification par (campagne, utilisateur)."""
    sent = 0
    for campaign in Campaign.objects.filter(status=CampaignStatus.SCHEDULED, scheduled_at__lte=timezone.now()):
        with transaction.atomic():
            locked = Campaign.objects.select_for_update().get(pk=campaign.pk)
            if locked.status != CampaignStatus.SCHEDULED:
                continue
            locked.status = CampaignStatus.SENDING
            locked.save(update_fields=["status", "updated_at"])
        audience = selectors.filter_by_tier(
            selectors.campaign_audience(campaign.segment), campaign.segment.get("tiers")
        )
        delivered = 0
        for user in audience:
            notification = services.notify(
                user=user,
                category="campaign",
                title=campaign.title,
                body=campaign.body,
                deeplink=campaign.deeplink,
                dedupe_key=f"campaign:{campaign.pk}",
                campaign=campaign,
            )
            delivered += int(notification is not None)
        Campaign.objects.filter(pk=campaign.pk).update(
            status=CampaignStatus.SENT, sent_count=F("sent_count") + delivered, updated_at=timezone.now()
        )
        sent += delivered
    return sent
