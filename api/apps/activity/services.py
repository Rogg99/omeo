"""
Écritures d'activity : pesées, connexion et synchronisation santé, activités, séances guidées, analyses croisées.

Toute écriture recalcule les jours concernés (`recompute_day`) dans la même transaction. Une nouvelle pesée
retenue met à jour `Profile.current_weight_kg` et relance le calcul des objectifs.
"""

from __future__ import annotations

from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Any, Final

from django.db import transaction
from django.db.models import Count, Max, Q, Sum
from django.utils import timezone, translation
from django.utils.translation import gettext as _

from apps.activity import met, trends
from apps.activity.models import (
    Activity,
    ActivitySource,
    DailyActivity,
    HealthConnection,
    Insight,
    WeightEntry,
    Workout,
    WorkoutSession,
)
from apps.core import events, settings_store
from apps.core.errors import Conflict, NotFound, ValidationFailed
from apps.core.i18n import LOCALES, to_django_locale
from apps.core.localtime import local_date_of, local_today
from apps.core.models import ContentStatus
from apps.nutrition import services as nutrition
from apps.nutrition.models import DailySummary

MANUAL_WINS: Final[tuple[str, ...]] = (
    ActivitySource.MANUAL,
    ActivitySource.HEALTH_CONNECT,
    ActivitySource.APPLE_HEALTH,
)


def _met_table() -> dict[str, dict[str, float]]:
    return dict(settings_store.get("activity.met_table"))


def _weight(user: Any) -> float:
    return float(user.profile.current_weight_kg)


# ───────────────────────── Poids ─────────────────────────


def _elect_effective(user: Any, day: date) -> None:
    """Une seule pesée retenue par jour : la saisie manuelle l'emporte, puis la plus récente."""
    entries = list(WeightEntry.objects.select_for_update().filter(user=user, date=day))
    WeightEntry.objects.filter(user=user, date=day, is_effective=True).update(is_effective=False)
    if not entries:
        return
    chosen = sorted(entries, key=lambda e: (MANUAL_WINS.index(e.source), -e.measured_at.timestamp()))[0]
    WeightEntry.objects.filter(pk=chosen.pk).update(is_effective=True)


def _sync_profile_weight(user: Any) -> None:
    latest = WeightEntry.objects.filter(user=user, is_effective=True).order_by("-date", "-measured_at").first()
    if latest is None:
        return
    profile = user.profile
    if profile.current_weight_kg != latest.weight_kg:
        profile.current_weight_kg = latest.weight_kg
        profile.save(update_fields=["current_weight_kg", "updated_at"])
        nutrition.recompute_targets(user=user)


@transaction.atomic
def add_weight(*, user: Any, weight_kg: Decimal, day: date | None = None) -> WeightEntry:
    day = nutrition.resolve_day(user=user, day=day)
    entry = WeightEntry.objects.create(
        user=user, date=day, weight_kg=weight_kg, source=ActivitySource.MANUAL, measured_at=timezone.now()
    )
    _elect_effective(user, day)
    _sync_profile_weight(user)
    nutrition.recompute_day(user=user, day=day)
    events.publish(events.WeightLogged(user_id=user.pk, entry_id=entry.pk, day=day))
    return entry


@transaction.atomic
def delete_weight(*, user: Any, entry_id: Any) -> None:
    entry = WeightEntry.objects.select_for_update().filter(pk=entry_id, user=user).first()
    if entry is None:
        raise NotFound()
    day = entry.date
    entry.delete()
    _elect_effective(user, day)
    _sync_profile_weight(user)
    nutrition.recompute_day(user=user, day=day)


# ───────────────────────── Santé connectée ─────────────────────────


@transaction.atomic
def set_health_connection(*, user: Any, source: str, granted_types: Sequence[str]) -> HealthConnection:
    connection, _created = HealthConnection.objects.update_or_create(
        user=user,
        defaults={"source": source, "granted_types": list(dict.fromkeys(granted_types)), "disconnected_at": None},
    )
    return connection


@transaction.atomic
def delete_health_connection(*, user: Any) -> None:
    HealthConnection.objects.filter(user=user).update(disconnected_at=timezone.now(), granted_types=[])


@dataclass(frozen=True, slots=True)
class SyncResult:
    days: list[DailySummary]
    merge_suggestions: list[tuple[Activity, Activity]]
    last_sync_at: datetime


def _activity_type(raw: str) -> str:
    mapping = {
        "walk": "walking",
        "walking": "walking",
        "run": "running",
        "running": "running",
        "soccer": "football",
        "football": "football",
        "dance": "dancing",
        "dancing": "dancing",
        "biking": "cycling",
        "cycling": "cycling",
        "strength_training": "strength",
        "strength": "strength",
        "weightlifting": "strength",
        "swimming": "swimming",
        "swimming_pool": "swimming",
    }
    return mapping.get(raw.strip().lower(), "other")


@transaction.atomic
def sync_health(
    *,
    user: Any,
    source: str,
    days: Sequence[dict[str, Any]],
    workouts: Sequence[dict[str, Any]],
    weights: Sequence[dict[str, Any]],
) -> SyncResult:
    """Upsert idempotent des totaux, séances et pesées lus sur l'appareil, puis recalcul des jours touchés."""
    today = local_today(user)
    oldest = today - timedelta(days=int(settings_store.get("activity.sync_max_days_back", 30)))
    touched: set[date] = set()

    for row in days:
        day = row["date"]
        if not oldest <= day <= today:
            raise ValidationFailed(errors={"days": [{"code": "out_of_range", "message": str(day)}]})
        DailyActivity.objects.update_or_create(
            user=user,
            date=day,
            source=source,
            defaults={
                "steps": row.get("steps", 0),
                "distance_m": row.get("distance_m", 0),
                "active_kcal": row.get("active_kcal", 0),
                "total_burned_kcal": row.get("total_burned_kcal"),
            },
        )
        touched.add(day)

    weight_kg = _weight(user)
    table = _met_table()
    imported: list[Activity] = []
    for row in workouts:
        started_at: datetime = row["started_at"]
        day = local_date_of(user, started_at)
        if not oldest <= day <= today:
            continue
        activity_type = _activity_type(row["type"])
        kcal = row.get("kcal")
        if kcal is None:
            kcal = met.kcal(
                met=met.met_for(table, activity_type, None), weight_kg=weight_kg, duration_s=row["duration_s"]
            )
        activity, _created = Activity.objects.update_or_create(
            user=user,
            source=source,
            external_id=row["external_id"],
            defaults={
                "date": day,
                "started_at": started_at,
                "duration_s": row["duration_s"],
                "type": activity_type,
                "kcal": kcal,
                "distance_m": row.get("distance_m"),
                "avg_hr": row.get("avg_hr"),
            },
        )
        imported.append(activity)
        touched.add(day)

    weight_days: set[date] = set()
    for row in weights:
        day = local_date_of(user, row["measured_at"])
        WeightEntry.objects.get_or_create(
            user=user,
            source=source,
            measured_at=row["measured_at"],
            defaults={"date": day, "weight_kg": Decimal(str(row["weight_kg"]))},
        )
        weight_days.add(day)
    for day in weight_days:
        _elect_effective(user, day)
    if weight_days:
        _sync_profile_weight(user)
    touched |= weight_days

    now = timezone.now()
    HealthConnection.objects.filter(user=user).update(last_sync_at=now)
    summaries = [nutrition.recompute_day(user=user, day=day) for day in sorted(touched)]
    return SyncResult(days=summaries, merge_suggestions=_merge_candidates(user, imported), last_sync_at=now)


def _merge_candidates(user: Any, imported: Iterable[Activity]) -> list[tuple[Activity, Activity]]:
    pairs = []
    for activity in imported:
        start = activity.started_at.timestamp()
        manual = Activity.objects.filter(
            user=user, date=activity.date, source=ActivitySource.MANUAL, merged_into__isnull=True
        )
        for candidate in manual:
            c_start = candidate.started_at.timestamp()
            if met.overlaps(start, start + activity.duration_s, c_start, c_start + candidate.duration_s):
                pairs.append((candidate, activity))
    return pairs


# ───────────────────────── Activités ─────────────────────────


@dataclass(frozen=True, slots=True)
class ActivityWrite:
    activity: Activity
    day: DailySummary
    merge_with: Activity | None = None


def _imported_overlap(user: Any, activity: Activity) -> Activity | None:
    start = activity.started_at.timestamp()
    for candidate in Activity.objects.filter(user=user, date=activity.date).exclude(
        source__in=[ActivitySource.MANUAL, ActivitySource.WORKOUT]
    ):
        c_start = candidate.started_at.timestamp()
        if met.overlaps(start, start + activity.duration_s, c_start, c_start + candidate.duration_s):
            return candidate
    return None


def _fill_manual(activity: Activity, *, user: Any, data: dict[str, Any]) -> None:
    started_at = data.get("started_at") or activity.started_at or timezone.now()
    if started_at > timezone.now():
        raise ValidationFailed(errors={"started_at": [{"code": "future", "message": "in the future"}]})
    activity.started_at = started_at
    activity.date = nutrition.resolve_day(user=user, day=data.get("date") or local_date_of(user, started_at))
    activity.type = data["type"]
    activity.intensity = data["intensity"]
    activity.duration_s = data["duration_s"]
    activity.label = data.get("label", "")
    activity.kcal = met.kcal(
        met=met.met_for(_met_table(), activity.type, activity.intensity),
        weight_kg=_weight(user),
        duration_s=activity.duration_s,
    )


@transaction.atomic
def create_activity(*, user: Any, data: dict[str, Any]) -> ActivityWrite:
    activity = Activity(user=user, source=ActivitySource.MANUAL)
    _fill_manual(activity, user=user, data=data)
    activity.save()
    summary = nutrition.recompute_day(user=user, day=activity.date)
    return ActivityWrite(activity=activity, day=summary, merge_with=_imported_overlap(user, activity))


def _own_activity(user: Any, activity_id: Any) -> Activity:
    activity = Activity.objects.select_for_update().filter(pk=activity_id, user=user).first()
    if activity is None:
        raise NotFound()
    return activity


@transaction.atomic
def update_activity(*, user: Any, activity_id: Any, data: dict[str, Any]) -> ActivityWrite:
    activity = _own_activity(user, activity_id)
    if activity.source != ActivitySource.MANUAL:
        raise Conflict(detail="only manual activities are editable")
    old_day = activity.date
    _fill_manual(activity, user=user, data=data)
    activity.save()
    if old_day != activity.date:
        nutrition.recompute_day(user=user, day=old_day)
    summary = nutrition.recompute_day(user=user, day=activity.date)
    return ActivityWrite(activity=activity, day=summary, merge_with=_imported_overlap(user, activity))


@transaction.atomic
def delete_activity(*, user: Any, activity_id: Any) -> DailySummary:
    activity = _own_activity(user, activity_id)
    day = activity.date
    activity.delete()
    return nutrition.recompute_day(user=user, day=day)


@transaction.atomic
def merge_activity(*, user: Any, activity_id: Any, into_id: Any) -> ActivityWrite:
    manual = _own_activity(user, activity_id)
    target = Activity.objects.filter(pk=into_id, user=user).first()
    if target is None:
        raise NotFound()
    if manual.source != ActivitySource.MANUAL or target.source in (ActivitySource.MANUAL, ActivitySource.WORKOUT):
        raise ValidationFailed(
            errors={"into_id": [{"code": "invalid", "message": "merge a manual entry into an import"}]}
        )
    manual.merged_into = target
    manual.save(update_fields=["merged_into", "updated_at"])
    if not target.label and manual.label:
        target.label = manual.label
        target.save(update_fields=["label", "updated_at"])
    return ActivityWrite(activity=target, day=nutrition.recompute_day(user=user, day=target.date))


# ───────────────────────── Séances guidées ─────────────────────────


@dataclass(frozen=True, slots=True)
class SessionWrite:
    session: WorkoutSession
    day: DailySummary


@transaction.atomic
def complete_workout_session(
    *, user: Any, workout_id: Any, started_at: datetime, ended_at: datetime, completed_steps: int
) -> SessionWrite:
    workout = Workout.objects.filter(pk=workout_id, status=ContentStatus.PUBLISHED).first()
    if workout is None:
        raise NotFound()
    if ended_at <= started_at or ended_at > timezone.now() + timedelta(minutes=5):
        raise ValidationFailed(errors={"ended_at": [{"code": "invalid", "message": "invalid time range"}]})
    steps = list(workout.steps.select_related("exercise"))
    completed_steps = min(completed_steps, len(steps))
    seconds_per_rep = int(settings_store.get("activity.seconds_per_rep", 3))
    efforts = [
        met.StepEffort(
            met=float(step.exercise.met),
            seconds=met.step_seconds(
                mode=step.mode, duration_s=step.duration_s, reps=step.reps, seconds_per_rep=seconds_per_rep
            ),
        )
        for step in steps[:completed_steps]
    ]
    duration_s = int((ended_at - started_at).total_seconds())
    kcal = met.kcal(met=met.average_met(efforts), weight_kg=_weight(user), duration_s=duration_s)
    day = nutrition.resolve_day(user=user, day=local_date_of(user, started_at))
    session = WorkoutSession.objects.create(
        user=user,
        workout=workout,
        date=day,
        started_at=started_at,
        completed_at=ended_at,
        duration_s=duration_s,
        completed_steps=completed_steps,
        completed=completed_steps == len(steps) and len(steps) > 0,
        kcal=kcal,
    )
    summary = nutrition.recompute_day(user=user, day=day)
    if session.completed:
        events.publish(events.WorkoutCompleted(user_id=user.pk, session_id=session.pk, day=day))
    return SessionWrite(session=session, day=summary)


# ───────────────────────── Projection ─────────────────────────


def day_contribution(user: Any, day: date) -> dict[str, Any]:
    """Part d'activity dans `DailySummary` (enregistrée dans ActivityConfig.ready)."""
    totals = DailyActivity.objects.filter(user=user, date=day).aggregate(
        steps=Max("steps"), distance=Max("distance_m"), active=Max("active_kcal"), burned=Max("total_burned_kcal")
    )
    manual = Activity.objects.filter(
        user=user, date=day, source=ActivitySource.MANUAL, merged_into__isnull=True
    ).aggregate(kcal=Sum("kcal"), seconds=Sum("duration_s"))
    imported = Activity.objects.filter(
        user=user, date=day, source__in=[ActivitySource.HEALTH_CONNECT, ActivitySource.APPLE_HEALTH]
    ).aggregate(seconds=Sum("duration_s"))
    sessions = WorkoutSession.objects.filter(user=user, date=day).aggregate(
        kcal=Sum("kcal"), seconds=Sum("duration_s"), completed=Count("id", filter=Q(completed=True))
    )
    extra_kcal = int(manual["kcal"] or 0) + int(sessions["kcal"] or 0)
    burned = totals["burned"]
    return {
        "steps": int(totals["steps"] or 0),
        "distance_m": int(totals["distance"] or 0),
        "active_kcal": int(totals["active"] or 0) + extra_kcal,
        "burned_kcal": int(burned) + extra_kcal if burned is not None else None,
        "active_minutes": (int(manual["seconds"] or 0) + int(imported["seconds"] or 0) + int(sessions["seconds"] or 0))
        // 60,
        "workouts_completed": int(sessions["completed"] or 0),
        "weight_logged": WeightEntry.objects.filter(user=user, date=day, is_effective=True).exists(),
    }


# ───────────────────────── Analyses croisées ─────────────────────────


def insight_message(kind: str, data: dict[str, Any]) -> str:
    """Texte d'une analyse croisée dans la langue active."""
    if kind == "active_days_intake":
        difference = int(data["difference_kcal"])
        if difference >= 0:
            text = _("Les jours où tu atteins ton objectif de pas, tu manges en moyenne %(diff)s kcal de plus.")
        else:
            text = _("Les jours où tu atteins ton objectif de pas, tu manges en moyenne %(diff)s kcal de moins.")
        return text % {"diff": abs(difference)}
    return _("Tu as atteint ton objectif de %(goal)s pas %(days)s jour(s) cette semaine.") % {
        "goal": data["goal"],
        "days": data["days"],
    }


@transaction.atomic
def generate_weekly_insights(*, user: Any, week_start: date) -> list[Insight]:
    """Idempotent : une analyse par (semaine, type). Messages rendus dans les 8 langues."""
    summaries = DailySummary.objects.filter(user=user, date__gte=week_start, date__lt=week_start + timedelta(days=7))
    points = [
        trends.DayPoint(day=s.date, steps=s.steps, consumed_kcal=s.consumed_kcal, meals_count=s.meals_count)
        for s in summaries
    ]
    goal = int(settings_store.get("activity.steps_goal", 8000))
    candidates = (trends.active_vs_rest_intake(points, steps_goal=goal), trends.steps_streak(points, steps_goal=goal))
    drafts = [draft for draft in candidates if draft is not None]
    created = []
    for draft in drafts:
        message = {}
        for locale in LOCALES:
            with translation.override(to_django_locale(locale)):
                message[locale] = insight_message(draft.kind, dict(draft.data))
        insight, _created = Insight.objects.update_or_create(
            user=user, week_start=week_start, kind=draft.kind, defaults={"message": message, "data": draft.data}
        )
        created.append(insight)
    return created
