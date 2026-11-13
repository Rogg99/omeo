"""Offres, quotas, essai, jours offerts et abonnements (paiements, promos et webhooks arrivent avec le module billing)."""

from __future__ import annotations

from typing import ClassVar

from django.conf import settings
from django.db import models
from django.db.models import Q

from apps.core.i18n import I18nTextField
from apps.core.models import BaseModel


class PlanTier(models.TextChoices):
    TRIAL = "trial"
    FREE = "free"
    PLUS = "plus"


class Interval(models.TextChoices):
    MONTH = "month"
    YEAR = "year"
    NONE = "none"


class Plan(BaseModel):
    code = models.CharField(max_length=24, unique=True)
    name = I18nTextField()
    price_cents = models.PositiveIntegerField(default=0)
    currency = models.CharField(max_length=3, default="USD")
    interval = models.CharField(max_length=5, choices=Interval.choices, default=Interval.NONE)
    is_featured = models.BooleanField(default=False)
    store_product_ids = models.JSONField(default=dict)
    web_price_id = models.CharField(max_length=120, blank=True)
    active = models.BooleanField(default=True)

    @property
    def tier(self) -> str:
        if self.code.startswith("plus"):
            return PlanTier.PLUS
        return self.code


class QuotaFeature(models.TextChoices):
    PHOTO_ANALYSIS = "photo_analysis"
    TEXT_ANALYSIS = "text_analysis"
    CHALLENGES_ACTIVE = "challenges_active"


class QuotaPeriod(models.TextChoices):
    DAY = "day"
    MONTH = "month"
    TRIAL = "trial"


class QuotaRule(BaseModel):
    plan_tier = models.CharField(max_length=5, choices=PlanTier.choices)
    feature = models.CharField(max_length=20, choices=QuotaFeature.choices)
    limit = models.PositiveIntegerField(null=True, blank=True)  # vide = illimité
    period = models.CharField(max_length=5, choices=QuotaPeriod.choices)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["plan_tier", "feature"], name="quota_rule_tier_feature_uniq"),
        ]


class TrialSource(models.TextChoices):
    SIGNUP = "signup"
    REFERRAL = "referral"


class Trial(BaseModel):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="trial")
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    extended_by_days = models.PositiveSmallIntegerField(default=0)
    source = models.CharField(max_length=8, choices=TrialSource.choices, default=TrialSource.SIGNUP)


class GrantReason(models.TextChoices):
    REFERRAL = "referral"
    SUPPORT = "support"
    PROMO = "promo"


class GrantedDays(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="granted_days")
    days = models.PositiveSmallIntegerField()
    reason = models.CharField(max_length=8, choices=GrantReason.choices)
    ref_id = models.CharField(max_length=64, blank=True)
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )

    class Meta:
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["user", "-ends_at"])]


class Channel(models.TextChoices):
    GOOGLE_PLAY = "google_play"
    APP_STORE = "app_store"
    WEB = "web"
    GRANT = "grant"


class SubscriptionStatus(models.TextChoices):
    TRIAL = "trial"
    ACTIVE = "active"
    GRACE = "grace"
    CANCELED = "canceled"
    EXPIRED = "expired"
    REFUNDED = "refunded"


ENTITLING_STATUSES: tuple[str, ...] = (
    SubscriptionStatus.TRIAL,
    SubscriptionStatus.ACTIVE,
    SubscriptionStatus.GRACE,
    SubscriptionStatus.CANCELED,  # résilié : l'accès court jusqu'à la fin de la période payée
)


class Subscription(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="subscriptions")
    plan = models.ForeignKey(Plan, on_delete=models.PROTECT, related_name="+")
    channel = models.CharField(max_length=12, choices=Channel.choices)
    status = models.CharField(max_length=10, choices=SubscriptionStatus.choices)
    current_period_start = models.DateTimeField()
    current_period_end = models.DateTimeField(db_index=True)
    auto_renew = models.BooleanField(default=True)
    external_id = models.CharField(max_length=255)
    raw = models.JSONField(default=dict)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["channel", "external_id"], name="subscription_channel_external_uniq"),
        ]
        indexes: ClassVar[list[models.Index]] = [
            models.Index(
                fields=["user", "current_period_end"],
                condition=Q(status__in=["trial", "active", "grace", "canceled"]),
                name="subscription_entitling_idx",
            ),
        ]
