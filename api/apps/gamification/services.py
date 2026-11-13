"""
Attribution des points, niveaux, badges et séries. Tout est calculé ici ; le mobile affiche.

Les autres applications publient des événements (MealLogged, DayRecomputed…) auxquels ce module est abonné, ou
appellent `award` / `bump` directement (challenges, programmes, parrainage, contenus consultés). Les points
gagnés pendant une requête remontent dans `RewardDelta` via `apps.core.rewards`.
"""

from __future__ import annotations

from datetime import date, timedelta
from typing import Any, Final

from django.contrib.auth import get_user_model
from django.db import IntegrityError, transaction
from django.db.models import Sum
from django.utils import timezone

from apps.billing.services import entitlement_for
from apps.core import events, rewards, settings_store
from apps.core.i18n import resolve
from apps.core.localtime import local_today
from apps.core.storage import public_url
from apps.gamification import rules, selectors
from apps.gamification.models import Badge, Level, PointEvent, PointRule, UserBadge, UserStats
from apps.nutrition import calculations
from apps.nutrition.constants import nutrition_constants
from apps.nutrition.models import DailySummary

STREAK_LOOKBACK_DAYS: Final = 400


def stats_for(user: Any, *, for_update: bool = False) -> UserStats:
    UserStats.objects.get_or_create(user=user)
    queryset = UserStats.objects.select_related("level")
    if for_update:
        queryset = queryset.select_for_update()
    return queryset.get(user=user)


def _levels() -> list[Level]:
    return list(Level.objects.order_by("min_points"))


def level_info(level: Level | None) -> dict[str, Any] | None:
    if level is None:
        return None
    body: dict[str, Any] = {"rank": level.rank, "name": resolve(level.name), "min_points": level.min_points}
    if level.icon_key:
        body["icon"] = {"url": public_url(level.icon_key)}
    return body


def badge_ref(badge: Badge) -> dict[str, Any]:
    body: dict[str, Any] = {"id": badge.id, "code": badge.code, "name": resolve(badge.name)}
    if badge.icon_key:
        body["icon"] = {"url": public_url(badge.icon_key)}
    return body


def _refresh_level(stats: UserStats) -> None:
    levels = _levels()
    if not levels:
        return
    by_rank = {lvl.rank: lvl for lvl in levels}
    current, _following = rules.level_for(
        stats.total_points, [rules.LevelStep(rank=lvl.rank, min_points=lvl.min_points) for lvl in levels]
    )
    new_level = by_rank[current.rank]
    if stats.level_id != new_level.pk:
        leveled_up = stats.level is not None and new_level.rank > stats.level.rank
        stats.level = new_level
        if leveled_up:
            rewards.set_totals(
                total_points=stats.total_points, streak=stats.current_streak, level_up=level_info(new_level)
            )


def _add_points(stats: UserStats, points: int) -> None:
    stats.total_points += points
    _refresh_level(stats)
    stats.save()
    rewards.add_points(points)
    rewards.set_totals(total_points=stats.total_points, streak=stats.current_streak)


@transaction.atomic
def award(*, user: Any, action: str, ref_type: str, ref_id: Any, day: date | None = None) -> int:
    """
    Attribue les points d'une action, une seule fois par référence et dans la limite du plafond.
    Verrouille `UserStats` : deux écritures simultanées ne dépassent jamais le plafond. Renvoie les points gagnés.
    """
    rule = PointRule.objects.filter(action=action).first()
    if rule is None or rule.points == 0:
        return 0
    day = day or local_today(user)
    stats = stats_for(user, for_update=True)
    start = rules.period_start(day, rule.cap_period)
    if start is not None:
        already = PointEvent.objects.filter(user=user, action=action, date__gte=start, date__lte=day).count()
        if not rules.within_cap(already=already, cap=rule.cap):
            return 0
    try:
        with transaction.atomic():
            PointEvent.objects.create(
                user=user, action=action, points=rule.points, date=day, ref_type=ref_type, ref_id=str(ref_id)
            )
    except IntegrityError:
        return 0
    _add_points(stats, rule.points)
    return rule.points


@transaction.atomic
def bump(*, user: Any, metric: str, value: float | None = None, increment: int = 1) -> None:
    """Met à jour un compteur de badge (`value` : maximum observé ; sinon incrément) puis réévalue les badges."""
    stats = stats_for(user, for_update=True)
    counters = dict(stats.counters)
    if value is not None:
        counters[metric] = max(float(counters.get(metric, 0)), float(value))
    else:
        counters[metric] = float(counters.get(metric, 0)) + increment
    stats.counters = counters
    stats.save(update_fields=["counters", "updated_at"])
    evaluate_badges(user=user, stats=stats)


@transaction.atomic
def evaluate_badges(*, user: Any, stats: UserStats | None = None) -> list[Badge]:
    stats = stats or stats_for(user, for_update=True)
    metrics = selectors.metrics(stats)
    earned: list[Badge] = []
    owned = {ub.badge_id: ub for ub in UserBadge.objects.select_for_update().filter(user=user)}
    for badge in Badge.objects.filter(status="published"):
        _value, _threshold, ratio = rules.badge_progress(badge.condition, metrics)
        user_badge = owned.get(badge.pk) or UserBadge(user=user, badge=badge)
        if user_badge.earned_at is not None:
            continue
        user_badge.progress = round(ratio, 3)  # type: ignore[assignment]
        if ratio >= 1:
            user_badge.earned_at = timezone.now()
            earned.append(badge)
        user_badge.save()
    for badge in earned:
        rewards.add_badge(badge_ref(badge))
        if badge.bonus_points:
            _add_points(stats_for(user, for_update=True), badge.bonus_points)
            PointEvent.objects.get_or_create(
                user=user,
                action="badge_bonus",
                ref_type="badge",
                ref_id=str(badge.pk),
                defaults={"points": badge.bonus_points, "date": local_today(user)},
            )
    return earned


@transaction.atomic
def refresh_streak(*, user: Any) -> int:
    today = local_today(user)
    logged = set(
        DailySummary.objects.filter(
            user=user, meals_count__gt=0, date__gte=today - timedelta(days=STREAK_LOOKBACK_DAYS)
        ).values_list("date", flat=True)
    )
    result = rules.streak(logged_days=logged, today=today, freeze_allowed=entitlement_for(user).allows("streak_freeze"))
    stats = stats_for(user, for_update=True)
    week_start = today - timedelta(days=today.weekday())
    stats.current_streak = result.current
    stats.best_streak = max(stats.best_streak, result.current)
    stats.streak_freezes_used_week = sum(1 for d in result.freezes_used if d >= week_start)
    stats.last_meal_date = max(logged) if logged else None
    stats.save()
    rewards.set_totals(total_points=stats.total_points, streak=stats.current_streak)
    evaluate_badges(user=user, stats=stats)
    return result.current


def week_points(*, user: Any) -> int:
    today = local_today(user)
    start = today - timedelta(days=today.weekday())
    return int(PointEvent.objects.filter(user=user, date__gte=start).aggregate(total=Sum("points"))["total"] or 0)


# ───────────────────────── Abonnements aux événements ─────────────────────────


def _on_meal_logged(event: events.MealLogged) -> None:
    user = _user(event.user_id)
    award(user=user, action="meal_logged", ref_type="meal", ref_id=event.meal_id, day=event.day)
    bump(user=user, metric="meals_total")
    refresh_streak(user=user)


def _on_day_recomputed(event: events.DayRecomputed) -> None:
    summary = DailySummary.objects.filter(user_id=event.user_id, date=event.day).first()
    if summary is None:
        return
    user = _user(event.user_id)
    ref = event.day.isoformat()
    if summary.is_complete:
        award(user=user, action="day_complete", ref_type="day", ref_id=ref, day=event.day)
    if summary.target_water_ml and summary.water_ml >= summary.target_water_ml:
        if award(user=user, action="water_goal", ref_type="day", ref_id=ref, day=event.day):
            bump(user=user, metric="water_goal_days")
    steps_goal = _steps_goal()
    if summary.steps >= steps_goal and award(user=user, action="steps_goal", ref_type="day", ref_id=ref, day=event.day):
        bump(user=user, metric="steps_goal_days")
    if summary.steps:
        bump(user=user, metric="steps_day_max", value=summary.steps)


def close_day(*, user: Any, day: date) -> None:
    """Fin de journée locale : l'objectif calorique n'est jugé qu'une fois la journée terminée."""
    summary = DailySummary.objects.filter(user=user, date=day).first()
    if summary is None or not summary.is_complete:
        return
    if calculations.kcal_within_target(
        consumed=summary.consumed_kcal, target=summary.target_kcal, c=nutrition_constants()
    ) and award(user=user, action="kcal_goal", ref_type="day", ref_id=day.isoformat(), day=day):
        bump(user=user, metric="kcal_goal_days")
    refresh_streak(user=user)


def _on_workout_completed(event: events.WorkoutCompleted) -> None:
    user = _user(event.user_id)
    award(user=user, action="workout_completed", ref_type="workout_session", ref_id=event.session_id, day=event.day)
    bump(user=user, metric="workouts_total")


def _on_weight_logged(event: events.WeightLogged) -> None:
    award(user=_user(event.user_id), action="weight_logged", ref_type="weight", ref_id=event.entry_id, day=event.day)


def _on_feedback_given(event: events.FeedbackGiven) -> None:
    award(user=_user(event.user_id), action="feedback_given", ref_type="analysis", ref_id=event.analysis_id)


def _user(user_id: Any) -> Any:
    return get_user_model().objects.select_related("profile").get(pk=user_id)


def _steps_goal() -> int:
    return int(settings_store.get("activity.steps_goal", 8000))


def connect_events() -> None:
    events.subscribe(events.MealLogged, _on_meal_logged)
    events.subscribe(events.DayRecomputed, _on_day_recomputed)
    events.subscribe(events.WorkoutCompleted, _on_workout_completed)
    events.subscribe(events.WeightLogged, _on_weight_logged)
    events.subscribe(events.FeedbackGiven, _on_feedback_given)


def level_progress(*, total_points: int) -> tuple[Level | None, Level | None, int]:
    """Niveau courant, niveau suivant et progression (%) pour un total de points."""
    levels = _levels()
    if not levels:
        return None, None, 0
    by_rank = {lvl.rank: lvl for lvl in levels}
    current, following = rules.level_for(
        total_points, [rules.LevelStep(rank=lvl.rank, min_points=lvl.min_points) for lvl in levels]
    )
    return (
        by_rank[current.rank],
        by_rank[following.rank] if following else None,
        rules.progress_percent(total_points, current, following),
    )


def rewards_summary(*, user: Any) -> dict[str, Any]:
    stats = stats_for(user)
    level, _following, percent = level_progress(total_points=stats.total_points)
    return {
        "level": level_info(level),
        "total_points": stats.total_points,
        "streak": stats.current_streak,
        "progress_to_next_percent": percent,
    }
