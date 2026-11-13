"""Données « vue » d'activity, prêtes à afficher : courbe de poids et écran Sport."""

from __future__ import annotations

from datetime import date, timedelta
from typing import Any, Final

from apps.activity import met, selectors, trends
from apps.activity import serializers as s
from apps.activity.models import Workout
from apps.core import settings_store
from apps.nutrition import calculations
from apps.nutrition import selectors as nutrition_selectors
from apps.nutrition.calculations import NutritionConstants
from apps.nutrition.serializers import BALANCE_LABELS

WEIGHT_RANGES: Final[dict[str, int | None]] = {"30d": 30, "90d": 90, "1y": 365, "all": None}


def weight_overview(*, user: Any, range_key: str, today: date) -> dict[str, Any]:
    days = WEIGHT_RANGES[range_key]
    since = today - timedelta(days=days - 1) if days else None
    entries = selectors.effective_weights(user=user, since=since)
    profile = user.profile
    target = float(profile.target_weight_kg)
    current = float(entries[-1].weight_kg) if entries else None

    window = int(settings_store.get("activity.weight_trend_days", 28))
    recent = [
        trends.WeightPoint(day=e.date, weight_kg=float(e.weight_kg)) for e in entries if e.date > today - timedelta(days=window)
    ]
    slope = trends.kg_per_week(recent)
    return {
        "current_kg": current,
        "target_kg": target,
        "remaining_kg": calculations.round_1(abs(current - target)) if current is not None else None,
        "start_kg": float(entries[0].weight_kg) if entries else None,
        "trend": trends.trend_label(slope, stable_threshold=float(settings_store.get("activity.weight_stable_kg_per_week", 0.1))),
        "trend_kg_per_week": slope,
        "bmi": trends.bmi(weight_kg=current, height_cm=float(profile.height_cm)),
        "series": [
            {"id": e.id, "date": e.date, "weight_kg": float(e.weight_kg), "source": e.source} for e in entries
        ],
        "next_reminder": None,
    }


def estimated_kcal(workout: Workout, *, weight_kg: float) -> int:
    steps = list(workout.steps.all())
    seconds_per_rep = int(settings_store.get("activity.seconds_per_rep", 3))
    efforts = [
        met.StepEffort(
            met=float(step.exercise.met),
            seconds=met.step_seconds(
                mode=step.mode, duration_s=step.duration_s, reps=step.reps, seconds_per_rep=seconds_per_rep
            ),
        )
        for step in steps
    ]
    return met.kcal(met=met.average_met(efforts), weight_kg=weight_kg, duration_s=workout.duration_s)


def activity_overview(*, user: Any, day: date, c: NutritionConstants, locked: bool) -> dict[str, Any]:
    views = nutrition_selectors.day_views_between(user=user, start=day - timedelta(days=6), end=day)
    summary = views[day]
    target = nutrition_selectors.target_on(user=user, day=day)
    tdee = target.tdee_kcal if target else 0

    def burned(view: Any) -> int:
        # Sans dépense importée : dépense de base estimée + activité enregistrée
        return int(view.burned_kcal) if view.burned_kcal is not None else tdee + int(view.active_kcal)

    balance = calculations.balance(consumed_kcal=summary.consumed_kcal, burned_kcal=burned(summary)) or {}
    balance["label"] = str(BALANCE_LABELS[balance["status"]])
    goal = int(settings_store.get("activity.steps_goal", 8000))
    return {
        "date": day,
        "steps": calculations.gauge(value=summary.steps, target=goal, c=c),
        "distance_m": summary.distance_m,
        "active_kcal": summary.active_kcal,
        "active_minutes": summary.active_minutes,
        "health": s.health_out(selectors.health_connection(user=user)),
        "balance_day": balance,
        "balance_week": [
            {"date": d, "consumed_kcal": v.consumed_kcal, "burned_kcal": burned(v)} for d, v in sorted(views.items())
        ],
        "activities": [s.activity_out(a) for a in selectors.activities_on(user=user, day=day)],
        "recommended_workouts": [
            s.workout_summary_out(w, locked=locked and not w.is_free) for w in selectors.recommended_workouts()
        ],
    }
