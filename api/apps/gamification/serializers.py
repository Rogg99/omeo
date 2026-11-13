"""Sorties de gamification (prêtes à afficher)."""

from __future__ import annotations

from typing import Any, Final

from django.utils.translation import gettext_lazy as _

from apps.core.i18n import resolve
from apps.gamification import rules
from apps.gamification.models import Badge, PointEvent, UserBadge
from apps.gamification.services import badge_ref
from apps.nutrition.calculations import round_int

ACTION_LABELS: Final[dict[str, Any]] = {
    "meal_logged": _("Repas enregistré"),
    "day_complete": _("Journée complète"),
    "water_goal": _("Objectif d'eau atteint"),
    "kcal_goal": _("Objectif calorique respecté"),
    "steps_goal": _("Objectif de pas atteint"),
    "workout_completed": _("Séance terminée"),
    "weight_logged": _("Pesée enregistrée"),
    "challenge_day": _("Jour de challenge réussi"),
    "challenge_completed": _("Challenge réussi"),
    "program_completed": _("Programme terminé"),
    "feedback_given": _("Avis sur une analyse"),
    "referral_validated": _("Filleul inscrit"),
    "badge_bonus": _("Bonus de badge"),
}


def user_badge_out(badge: Badge, owned: UserBadge | None, metrics: dict[str, float]) -> dict[str, Any]:
    value, threshold, ratio = rules.badge_progress(badge.condition, metrics)
    earned = owned is not None and owned.earned_at is not None
    if earned:
        state, ratio = "earned", 1.0
    else:
        state = "in_progress" if ratio > 0 else "locked"
    return {
        "badge": badge_ref(badge),
        "family": badge.family,
        "description": resolve(badge.description),
        "state": state,
        "progress_percent": round_int(ratio * 100),
        "progress_label": f"{int(min(value, threshold))} / {int(threshold)}",
        "earned_at": owned.earned_at if owned else None,
    }


def point_event_out(event: PointEvent) -> dict[str, Any]:
    return {
        "id": event.id,
        "action": event.action,
        "label": str(ACTION_LABELS.get(event.action, event.action)),
        "points": event.points,
        "date": event.date,
    }
