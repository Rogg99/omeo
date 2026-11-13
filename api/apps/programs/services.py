"""
Programmes et challenges : inscription, validation automatique (contre DailySummary) ou manuelle, clôture.

La validation automatique est réévaluée après chaque `recompute_day` (événement DayRecomputed) et figée à la fin de
la journée locale par la tâche `close_days`. Les points passent par gamification.
"""

from __future__ import annotations

from datetime import date, timedelta
from decimal import Decimal
from typing import Any

from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.billing.models import QuotaRule
from apps.billing.services import entitlement_for, quota_exceeded, quota_state
from apps.core import events
from apps.core.errors import Conflict, NotFound, ValidationFailed
from apps.core.localtime import local_today
from apps.core.models import ContentStatus
from apps.core.permissions import require_feature
from apps.gamification import services as gamification
from apps.nutrition import calculations
from apps.nutrition.constants import nutrition_constants
from apps.nutrition.models import DailySummary
from apps.programs import rules
from apps.programs.models import (
    Challenge,
    ChallengeDay,
    ChallengeDayStatus,
    ChallengeParticipation,
    Enrollment,
    EnrollmentStatus,
    Metric,
    ParticipationStatus,
    Program,
    ProgramTask,
    Rule,
    TaskCompletion,
    TaskSource,
)


def day_values(summary: DailySummary | None) -> dict[str, float]:
    """Valeurs du jour pour l'évaluation des règles."""
    if summary is None:
        return {}
    within = summary.meals_count > 0 and calculations.kcal_within_target(
        consumed=summary.consumed_kcal, target=summary.target_kcal, c=nutrition_constants()
    )
    return {
        "water_ml": summary.water_ml,
        "steps": summary.steps,
        "active_minutes": summary.active_minutes,
        "meals_count": summary.meals_count,
        "protein_g": float(summary.protein_g),
        "kcal_within_target": 1.0 if within else 0.0,
        "workout_completed": float(summary.workouts_completed),
        "weight_logged": 1.0 if summary.weight_logged else 0.0,
    }


def rule_spec(rule: Rule) -> rules.RuleSpec:
    return rules.RuleSpec(metric=rule.metric, operator=rule.operator, threshold=float(rule.threshold))


# ───────────────────────── Programmes ─────────────────────────


@transaction.atomic
def enroll(*, user: Any, program_id: Any, replace: bool) -> Enrollment:
    require_feature(user, "programs")
    program = Program.objects.filter(pk=program_id, status=ContentStatus.PUBLISHED).first()
    if program is None:
        raise NotFound()
    active = Enrollment.objects.select_for_update().filter(user=user, status=EnrollmentStatus.ACTIVE).first()
    if active is not None:
        if active.program_id == program.pk:
            raise Conflict(code="already_enrolled", detail="program already active")
        if not replace:
            raise Conflict(
                code="already_enrolled", detail="another program is active", meta={"active_id": str(active.pk)}
            )
        active.status = EnrollmentStatus.REPLACED
        active.ended_at = timezone.now()
        active.save(update_fields=["status", "ended_at", "updated_at"])
    return Enrollment.objects.create(
        user=user, program=program, started_on=local_today(user), start_weight_kg=user.profile.current_weight_kg
    )


def active_enrollment(user: Any) -> Enrollment | None:
    return Enrollment.objects.filter(user=user, status=EnrollmentStatus.ACTIVE).select_related("program").first()


@transaction.atomic
def quit_program(*, user: Any) -> None:
    enrollment = Enrollment.objects.select_for_update().filter(user=user, status=EnrollmentStatus.ACTIVE).first()
    if enrollment is None:
        raise NotFound()
    enrollment.status = EnrollmentStatus.ABANDONED
    enrollment.ended_at = timezone.now()
    enrollment.save(update_fields=["status", "ended_at", "updated_at"])


def _task_of_day(enrollment: Enrollment, task_id: Any, day: date) -> ProgramTask:
    index = rules.day_index(enrollment.started_on, day)
    task = ProgramTask.objects.filter(pk=task_id, day__program=enrollment.program, day__day_index=index).first()
    if task is None:
        raise NotFound()
    return task


@transaction.atomic
def check_task(*, user: Any, task_id: Any, done: bool, day: date | None) -> Enrollment:
    require_feature(user, "programs")
    enrollment = active_enrollment(user)
    if enrollment is None:
        raise NotFound()
    today = local_today(user)
    day = day or today
    if day not in (today, today - timedelta(days=1)):
        raise ValidationFailed(errors={"date": [{"code": "out_of_range", "message": "today or yesterday only"}]})
    task = _task_of_day(enrollment, task_id, day)
    if task.rule_id is not None:
        raise Conflict(detail="automatic task")
    TaskCompletion.objects.update_or_create(
        enrollment=enrollment, task=task, date=day, defaults={"done": done, "source": TaskSource.MANUAL}
    )
    return enrollment


def _evaluate_enrollment(enrollment: Enrollment, day: date, values: dict[str, float]) -> None:
    index = rules.day_index(enrollment.started_on, day)
    tasks = ProgramTask.objects.filter(day__program=enrollment.program, day__day_index=index).select_related("rule")
    for task in tasks:
        if task.rule is None:
            continue  # tâche manuelle
        result = rules.evaluate(rule_spec(task.rule), values)
        TaskCompletion.objects.update_or_create(
            enrollment=enrollment,
            task=task,
            date=day,
            defaults={"done": result.passed, "progress": Decimal(str(result.progress)), "source": TaskSource.AUTO},
        )


@transaction.atomic
def finish_program_if_due(*, enrollment: Enrollment, today: date) -> bool:
    total_days = enrollment.program.weeks * 7
    if rules.day_index(enrollment.started_on, today) <= total_days:
        return False
    done_days = TaskCompletion.objects.filter(enrollment=enrollment, done=True).values("date").distinct().count()
    current_weight = enrollment.user.profile.current_weight_kg
    enrollment.status = EnrollmentStatus.COMPLETED
    enrollment.ended_at = timezone.now()
    enrollment.report = {
        "assiduity_percent": rules.percent(done_days, total_days),
        "start_weight_kg": float(enrollment.start_weight_kg) if enrollment.start_weight_kg else None,
        "end_weight_kg": float(current_weight),
    }
    enrollment.save(update_fields=["status", "ended_at", "report", "updated_at"])
    gamification.award(user=enrollment.user, action="program_completed", ref_type="enrollment", ref_id=enrollment.pk)
    gamification.bump(user=enrollment.user, metric="programs_completed")
    return True


# ───────────────────────── Challenges ─────────────────────────


def _challenge_limit(user: Any) -> int | None:
    tier = entitlement_for(user).tier
    rule = QuotaRule.objects.filter(plan_tier=tier, feature="challenges_active").first()
    return rule.limit if rule else None


@transaction.atomic
def join_challenge(*, user: Any, challenge_id: Any) -> ChallengeParticipation:
    challenge = Challenge.objects.filter(pk=challenge_id, status=ContentStatus.PUBLISHED).select_related("rule").first()
    if challenge is None:
        raise NotFound()
    active = ChallengeParticipation.objects.select_for_update().filter(user=user, status=ParticipationStatus.ACTIVE)
    if any(p.challenge_id == challenge.pk for p in active):
        raise Conflict(code="already_enrolled", detail="challenge already joined")
    limit = _challenge_limit(user)
    if limit is not None and active.count() >= limit:
        raise quota_exceeded(quota_state(user=user, feature="challenges_active"))
    try:
        with transaction.atomic():
            participation = ChallengeParticipation.objects.create(
                user=user, challenge=challenge, started_on=local_today(user)
            )
    except IntegrityError:
        raise Conflict(code="already_enrolled", detail="challenge already joined") from None
    if challenge.rule.metric != Metric.MANUAL:
        summary = DailySummary.objects.filter(user=user, date=participation.started_on).first()
        _evaluate_participation(participation, participation.started_on, day_values(summary))
    return participation


def own_participation(*, user: Any, participation_id: Any, for_update: bool = False) -> ChallengeParticipation:
    queryset = ChallengeParticipation.objects.filter(pk=participation_id, user=user).select_related("challenge__rule")
    if for_update:
        queryset = queryset.select_for_update()
    participation = queryset.first()
    if participation is None:
        raise NotFound()
    return participation


@transaction.atomic
def leave_challenge(*, user: Any, participation_id: Any) -> None:
    participation = own_participation(user=user, participation_id=participation_id, for_update=True)
    if participation.status != ParticipationStatus.ACTIVE:
        raise Conflict(detail="challenge not active")
    participation.status = ParticipationStatus.ABANDONED
    participation.save(update_fields=["status", "updated_at"])


def _ends_on(participation: ChallengeParticipation) -> date:
    return participation.started_on + timedelta(days=participation.challenge.duration_days - 1)


def _set_day(
    participation: ChallengeParticipation, day: date, *, status: str, value: float | None, source: str
) -> None:
    current = ChallengeDay.objects.filter(participation=participation, date=day).first()
    ChallengeDay.objects.update_or_create(
        participation=participation,
        date=day,
        defaults={"status": status, "value": Decimal(str(value)) if value is not None else None, "source": source},
    )
    newly_success = status == ChallengeDayStatus.SUCCESS and (current is None or current.status != status)
    if newly_success:
        gamification.award(
            user=participation.user,
            action="challenge_day",
            ref_type="challenge_day",
            ref_id=f"{participation.pk}:{day.isoformat()}",
            day=day,
        )
    _refresh_rate(participation)


def _refresh_rate(participation: ChallengeParticipation) -> None:
    statuses = list(ChallengeDay.objects.filter(participation=participation).values_list("status", flat=True))
    participation.success_rate = Decimal(str(round(rules.success_rate(statuses), 3)))
    participation.save(update_fields=["success_rate", "updated_at"])


@transaction.atomic
def check_challenge_day(*, user: Any, participation_id: Any, day: date, done: bool) -> ChallengeParticipation:
    participation = own_participation(user=user, participation_id=participation_id, for_update=True)
    if participation.status != ParticipationStatus.ACTIVE or participation.challenge.rule.metric != Metric.MANUAL:
        raise Conflict(detail="only active manual challenges can be checked")
    today = local_today(user)
    if day not in (today, today - timedelta(days=1)) or not participation.started_on <= day <= _ends_on(participation):
        raise ValidationFailed(errors={"date": [{"code": "out_of_range", "message": "today or yesterday only"}]})
    status = ChallengeDayStatus.SUCCESS if done else ChallengeDayStatus.PENDING
    _set_day(participation, day, status=status, value=1.0 if done else 0.0, source=TaskSource.MANUAL)
    return participation


def _evaluate_participation(participation: ChallengeParticipation, day: date, values: dict[str, float]) -> None:
    if not participation.started_on <= day <= _ends_on(participation):
        return
    result = rules.evaluate(rule_spec(participation.challenge.rule), values)
    status = ChallengeDayStatus.SUCCESS if result.passed else ChallengeDayStatus.PENDING
    _set_day(participation, day, status=status, value=result.value, source=TaskSource.AUTO)


@transaction.atomic
def finish_challenge_if_due(*, participation: ChallengeParticipation, today: date) -> bool:
    if today <= _ends_on(participation):
        return False
    _refresh_rate(participation)
    succeeded = participation.success_rate >= participation.challenge.success_threshold
    participation.status = ParticipationStatus.SUCCEEDED if succeeded else ParticipationStatus.FAILED
    participation.save(update_fields=["status", "updated_at"])
    if succeeded:
        gamification.award(
            user=participation.user, action="challenge_completed", ref_type="participation", ref_id=participation.pk
        )
        gamification.bump(user=participation.user, metric="challenges_succeeded")
    return True


# ───────────────────────── Événements et clôture ─────────────────────────


def _on_day_recomputed(event: events.DayRecomputed) -> None:
    summary = DailySummary.objects.filter(user_id=event.user_id, date=event.day).first()
    values = day_values(summary)
    for participation in ChallengeParticipation.objects.filter(
        user_id=event.user_id, status=ParticipationStatus.ACTIVE
    ).select_related("challenge__rule", "user"):
        if participation.challenge.rule.metric != Metric.MANUAL:
            _evaluate_participation(participation, event.day, values)
    enrollment = (
        Enrollment.objects.filter(user_id=event.user_id, status=EnrollmentStatus.ACTIVE)
        .select_related("program")
        .first()
    )
    if enrollment is not None:
        _evaluate_enrollment(enrollment, event.day, values)


@transaction.atomic
def close_day(*, user: Any, day: date) -> None:
    """Fin de journée locale : les jours encore en attente échouent, les participations échues sont clôturées."""
    today = day + timedelta(days=1)
    for participation in (
        ChallengeParticipation.objects.select_for_update()
        .filter(user=user, status=ParticipationStatus.ACTIVE)
        .select_related("challenge__rule", "user")
    ):
        if participation.started_on <= day <= _ends_on(participation):
            current = ChallengeDay.objects.filter(participation=participation, date=day).first()
            if current is None or current.status == ChallengeDayStatus.PENDING:
                _set_day(participation, day, status=ChallengeDayStatus.FAILED, value=None, source=TaskSource.AUTO)
        finish_challenge_if_due(participation=participation, today=today)
    enrollment = (
        Enrollment.objects.select_for_update()
        .filter(user=user, status=EnrollmentStatus.ACTIVE)
        .select_related("program", "user__profile")
        .first()
    )
    if enrollment is not None:
        finish_program_if_due(enrollment=enrollment, today=today)


def connect_events() -> None:
    events.subscribe(events.DayRecomputed, _on_day_recomputed)
