"""
Écrans de modération provisoires (Django admin), en attendant l'admin Next
(endpoints /admin/feedback du contrat).
"""

from __future__ import annotations

from typing import Any

from django.contrib import admin, messages
from django.db.models import QuerySet
from django.http import HttpRequest

from apps.foodscan import services
from apps.foodscan.models import ConfusionRule, DishKnowledge, ScanReview


@admin.register(DishKnowledge)
class DishKnowledgeAdmin(admin.ModelAdmin):
    list_display = ("name", "key", "scope", "country", "region", "origin", "is_active", "updated_at")
    list_filter = ("scope", "region", "country", "origin", "is_active")
    search_fields = ("name", "key", "visual_description")


@admin.register(ScanReview)
class ScanReviewAdmin(admin.ModelAdmin):
    list_display = ("__str__", "country", "status", "user", "created_at")
    list_filter = ("status", "country")
    search_fields = ("predicted_label", "correct_label", "predicted_key", "correct_key")
    readonly_fields = ("user", "analysis_id", "decided_by", "decided_at", "created_at")
    actions = ("approve", "reject")

    @admin.action(description="Valider (crée la règle immédiatement)")
    def approve(self, request: HttpRequest, queryset: QuerySet[ScanReview]) -> None:
        self._moderate(request, queryset, approve=True)

    @admin.action(description="Rejeter (retire l'avis du consensus)")
    def reject(self, request: HttpRequest, queryset: QuerySet[ScanReview]) -> None:
        self._moderate(request, queryset, approve=False)

    def _moderate(self, request: HttpRequest, queryset: QuerySet[ScanReview], *, approve: bool) -> None:
        for review in queryset:
            services.moderate_review(review=review, moderator=request.user, approve=approve)
        self.message_user(request, f"{queryset.count()} avis traités.", messages.SUCCESS)


@admin.register(ConfusionRule)
class ConfusionRuleAdmin(admin.ModelAdmin):
    list_display = ("country", "predicted_label", "correct_label", "support", "agreement", "origin", "status")
    list_filter = ("status", "origin", "country")
    search_fields = ("predicted_label", "correct_label", "hint")
    readonly_fields = ("support", "agreement", "created_at", "updated_at")

    def save_model(self, request: HttpRequest, obj: ConfusionRule, form: Any, change: bool) -> None:
        # Toute modification à la main fait de la règle une décision de
        # validateur : le recalcul du consensus ne la touchera plus.
        obj.origin = ConfusionRule.Origin.MODERATOR
        super().save_model(request, obj, form, change)
