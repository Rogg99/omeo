"""
Écrans agrégés en un seul appel : accueil (`GET /me/home`) et journal d'un jour (`GET /me/days/{date}`).

Budget : 8 requêtes SQL au plus sur le chemin chaud (réglages, droits, règles de quotas, niveaux et documents légaux
sont en cache). Les autres applications sont lues par leurs sélecteurs et présentateurs publics.
"""

from __future__ import annotations

from datetime import date, timedelta
from typing import Any, Final

from django.utils.translation import gettext as _
from django.utils.translation import gettext_lazy

from apps.accounts.presenters import legal_ref_out
from apps.accounts.selectors import pending_documents
from apps.activity.presenters import insight_out
from apps.activity.selectors import latest_unread_insight
from apps.billing.services import entitlement_for, quota_states
from apps.content.presenters import user_tip_out
from apps.content.selectors import latest_tip
from apps.core.localtime import local_now
from apps.gamification.services import rewards_summary
from apps.meals.presenters import meal_out
from apps.meals.selectors import meals_between
from apps.nutrition import calculations, selectors
from apps.nutrition.constants import nutrition_constants
from apps.nutrition.models import DailySummary
from apps.nutrition.presenters import day_summary_out, water_out
from apps.programs.presenters import challenge_today_out, program_today_out
from apps.programs.selectors import enrollment_for_home, participations_for_home

SHORTCUTS: Final = ["nutrition", "sport", "recipes", "plants"]
MEAL_TYPES: Final = ["breakfast", "lunch", "snack", "dinner"]
MEAL_TYPE_LABELS: Final[dict[str, Any]] = {
    "breakfast": gettext_lazy("Petit-déjeuner"),
    "lunch": gettext_lazy("Déjeuner"),
    "snack": gettext_lazy("Collation"),
    "dinner": gettext_lazy("Dîner"),
}
WEEKDAY_LABELS: Final = [
    gettext_lazy("Lun"),
    gettext_lazy("Mar"),
    gettext_lazy("Mer"),
    gettext_lazy("Jeu"),
    gettext_lazy("Ven"),
    gettext_lazy("Sam"),
    gettext_lazy("Dim"),
]
EVENING_HOUR: Final = 18
TRIAL_ENDING_HOURS: Final = 24
QUOTA_LOW: Final = 1


def _greeting(user: Any) -> str:
    now = local_now(user)
    template = _("Bonsoir, %(name)s") if now.hour >= EVENING_HOUR else _("Bonjour, %(name)s")
    return template % {"name": user.profile.first_name}


def _week(user: Any, today: date, rows: dict[date, DailySummary]) -> list[dict[str, Any]]:
    c = nutrition_constants()
    monday = today - timedelta(days=today.weekday())
    week = []
    for offset in range(7):
        day = monday + timedelta(days=offset)
        row = rows.get(day)
        if day > today:
            status = "future"
        elif row is None:
            status = "empty"
        else:
            status = calculations.day_status(
                meals_count=row.meals_count, consumed_kcal=row.consumed_kcal, target_kcal=row.target_kcal, c=c
            )
        week.append(
            {
                "date": day,
                "label": str(WEEKDAY_LABELS[offset]),
                "day_number": day.day,
                "is_today": day == today,
                "status": status,
            }
        )
    return week


def _today_view(user: Any, today: date, rows: dict[date, DailySummary]) -> DailySummary:
    row = rows.get(today)
    return row if row is not None else selectors.empty_day(day=today, target=selectors.target_on(user=user, day=today))


def _text_lock(*, text_allowed: bool, remaining: int | None) -> str | None:
    if not text_allowed:
        return "plan_required"
    return "quota_exceeded" if remaining == 0 else None


def _banner(kind: str, message: str, action: str) -> dict[str, Any]:
    return {"kind": kind, "message": message, "action": action}


def _quick_actions(entitlement: Any, states: dict[str, Any]) -> list[dict[str, Any]]:
    photo = states["photo_analysis"]
    text = states["text_analysis"]
    photo_out = photo.remaining == 0
    text_allowed = entitlement.allows("text_analysis")
    return [
        {
            "kind": "photo",
            "enabled": not photo_out,
            "locked_reason": "quota_exceeded" if photo_out else None,
            "remaining": photo.remaining,
        },
        {
            "kind": "voice",
            "enabled": text_allowed and text.remaining != 0,
            "locked_reason": "plan_required"
            if not text_allowed
            else ("quota_exceeded" if text.remaining == 0 else None),
            "remaining": text.remaining if text_allowed else None,
        },
        {"kind": "catalog", "enabled": True, "locked_reason": None, "remaining": None},
    ]


def _banners(
    user: Any, entitlement: Any, photo_remaining: int | None, week_rows: dict[date, DailySummary]
) -> list[dict[str, Any]]:
    banners: list[dict[str, Any]] = []
    if user.email_verified_at is None:
        banners.append(
            {
                "kind": "verify_email",
                "message": _("Vérifie ton adresse email pour sécuriser ton compte."),
                "action": "verify_email",
            }
        )
    ends = entitlement.trial_ends_at
    if entitlement.tier == "trial" and ends is not None:
        remaining_hours = (ends - local_now(user)).total_seconds() / 3600
        if remaining_hours <= TRIAL_ENDING_HOURS:
            banners.append(
                {"kind": "trial_ending", "message": _("Ton essai se termine bientôt."), "action": "subscribe"}
            )
    pending = pending_documents(user)
    if pending:
        banners.append(
            {
                "kind": "reaccept_terms",
                "message": _("Nos conditions ont changé : merci de les relire."),
                "action": legal_ref_out(pending[0])["kind"],
            }
        )
    if not any(row.steps for row in week_rows.values()):
        banners.append(
            {
                "kind": "connect_health",
                "message": _("Connecte ton appli santé pour suivre tes pas."),
                "action": "connect_health",
            }
        )
    if photo_remaining is not None and photo_remaining <= QUOTA_LOW:
        banners.append({"kind": "quota_low", "message": _("Il te reste peu d'analyses photo."), "action": "subscribe"})
    return banners


def build_home(*, user: Any, today: date) -> dict[str, Any]:
    c = nutrition_constants()
    monday = today - timedelta(days=today.weekday())
    rows = selectors.summaries_between(user=user, start=monday, end=today)
    entitlement = entitlement_for(user)
    states = {s.feature: s for s in quota_states(user=user, features=["photo_analysis", "text_analysis"])}
    enrollment = enrollment_for_home(user=user, today=today)
    insight = latest_unread_insight(user=user) if entitlement.allows("insights") else None
    tip = latest_tip(user=user)
    challenges = participations_for_home(user=user, today=today)
    return {
        "greeting": _greeting(user),
        "date": today,
        "week": _week(user, today, rows),
        "day": day_summary_out(_today_view(user, today, rows), c=c),
        "quick_actions": _quick_actions(entitlement, states),
        "active_program": program_today_out(enrollment, today=today) if enrollment else None,
        "active_challenges": [challenge_today_out(p, today=today) for p in challenges],
        "shortcuts": SHORTCUTS,
        "rewards": rewards_summary(user=user),
        "insight": insight_out(insight) if insight else None,
        "tip": user_tip_out(tip, plus=entitlement.tier == "plus", full_catalog=entitlement.allows("full_catalog"))
        if tip
        else None,
        "banners": _banners(user, entitlement, states["photo_analysis"].remaining, rows),
    }


def _message(summary: DailySummary, *, is_today: bool) -> str:
    c = nutrition_constants()
    status = calculations.day_status(
        meals_count=summary.meals_count, consumed_kcal=summary.consumed_kcal, target_kcal=summary.target_kcal, c=c
    )
    messages = {
        "empty": _("Commence par ton premier repas de la journée.")
        if is_today
        else _("Aucun repas enregistré ce jour-là."),
        "partial": _("Bon début ! Pense à enregistrer tes prochains repas."),
        "on_target": _("Bravo, ta journée est dans ton objectif."),
        "over": _("Un peu au-dessus de ton objectif : rien de grave, demain est un autre jour."),
        "under": _("Tu as peu mangé : veille à couvrir tes besoins."),
    }
    return str(messages[status])


def build_day(*, user: Any, day: date, today: date) -> dict[str, Any]:
    c = nutrition_constants()
    summary = selectors.day_view(user=user, day=day)
    meals = list(meals_between(user=user, start=day, end=day).order_by("eaten_at"))
    by_type: list[dict[str, Any]] = []
    for meal_type in MEAL_TYPES:
        group = [m for m in meals if m.meal_type == meal_type]
        by_type.append(
            {
                "meal_type": meal_type,
                "label": str(MEAL_TYPE_LABELS[meal_type]),
                "kcal": calculations.round_int(sum(float(m.kcal) for m in group)),
                "meals": [meal_out(m) for m in group],
            }
        )
    return {
        "day": day_summary_out(summary, c=c),
        "meals_by_type": by_type,
        "water": water_out(summary, c=c),
        "message": _message(summary, is_today=day == today),
        "previous_date": day - timedelta(days=1),
        "next_date": day + timedelta(days=1) if day < today else None,
    }
