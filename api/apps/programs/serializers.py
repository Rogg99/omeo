"""Entrées et sorties des programmes et challenges (vues prêtes à afficher)."""

from __future__ import annotations

from datetime import date, timedelta
from typing import Any

from django.utils.translation import gettext as _
from rest_framework import serializers

from apps.activity.serializers import workout_summary_out
from apps.content.serializers import recipe_summary_out
from apps.core.i18n import resolve
from apps.core.storage import public_url
from apps.gamification.services import badge_ref
from apps.nutrition.calculations import round_int
from apps.programs import rules
from apps.programs.models import Challenge, ChallengeParticipation, Enrollment, Program, ProgramDay, Rule, TaskCompletion

WEEK_DAYS = 7


class ProgramFilterSerializer(serializers.Serializer[Any]):
    goal = serializers.ChoiceField(
        choices=["lose_weight", "gain_muscle", "eat_balanced", "prevent_diabetes", "prevent_hypertension"],
        required=False,
    )


class EnrollSerializer(serializers.Serializer[Any]):
    replace = serializers.BooleanField(default=False)


class CheckTaskSerializer(serializers.Serializer[Any]):
    done = serializers.BooleanField()
    date = serializers.DateField(required=False)


class CheckDaySerializer(serializers.Serializer[Any]):
    done = serializers.BooleanField()


class ParticipationFilterSerializer(serializers.Serializer[Any]):
    status = serializers.ChoiceField(choices=["active", "finished"], required=False)


class DayQuerySerializer(serializers.Serializer[Any]):
    date = serializers.DateField(required=False)


def rule_label(rule: Rule, fallback: str) -> str:
    threshold = float(rule.threshold)
    labels = {
        "water_ml": lambda: _("Boire %(liters)s L d'eau") % {"liters": f"{threshold / 1000:g}".replace(".", ",")},
        "steps": lambda: _("Faire au moins %(steps)s pas") % {"steps": f"{int(threshold):,}".replace(",", " ")},
        "active_minutes": lambda: _("Bouger au moins %(minutes)s minutes") % {"minutes": int(threshold)},
        "meals_count": lambda: _("Enregistrer %(count)s repas") % {"count": int(threshold)},
        "protein_g": lambda: _("Manger au moins %(grams)s g de protéines") % {"grams": int(threshold)},
        "kcal_within_target": lambda: _("Respecter ton objectif calorique"),
        "workout_completed": lambda: _("Terminer une séance guidée"),
        "weight_logged": lambda: _("Te peser"),
    }
    builder = labels.get(rule.metric)
    return builder() if builder else fallback


def _image(key: str) -> dict[str, Any] | None:
    return {"url": public_url(key)} if key else None


def program_summary_out(program: Program, *, locked: bool, is_active: bool) -> dict[str, Any]:
    body: dict[str, Any] = {
        "id": program.id,
        "name": resolve(program.name),
        "description": resolve(program.description),
        "goal": program.goal,
        "weeks": program.weeks,
        "locked": locked,
        "is_active": is_active,
    }
    cover = _image(program.cover_key)
    if cover:
        body["cover"] = cover
    return body


def program_day_out(
    day_row: ProgramDay | None,
    *,
    index: int,
    day: date,
    today: date,
    done_map: dict[tuple[Any, date], TaskCompletion],
    full_catalog: bool,
) -> dict[str, Any]:
    tasks = []
    if day_row is not None:
        for task in day_row.tasks.all():
            completion = done_map.get((task.pk, day))
            tasks.append(
                {
                    "id": task.id,
                    "label": resolve(task.label),
                    "done": bool(completion and completion.done),
                    "validation": "auto" if task.rule_id else "manual",
                    "progress": float(completion.progress) if completion and completion.progress is not None else None,
                }
            )
    done = sum(1 for t in tasks if t["done"])
    return {
        "day_index": index,
        "date": day,
        "tip": resolve(day_row.tip) or None if day_row else None,
        "workout": workout_summary_out(day_row.workout, locked=False) if day_row and day_row.workout else None,
        "suggested_recipes": [recipe_summary_out(r, full_catalog=full_catalog) for r in day_row.suggested_recipes.all()]
        if day_row
        else [],
        "tasks": tasks,
        "status": rules.program_day_status(day=day, today=today, done=done, total=len(tasks)),
    }


def enrollment_out(
    enrollment: Enrollment,
    *,
    today: date,
    days: dict[int, ProgramDay],
    done_map: dict[tuple[Any, date], TaskCompletion],
    full_catalog: bool,
    done_days: int,
) -> dict[str, Any]:
    total_days = enrollment.program.weeks * WEEK_DAYS
    index = max(1, min(rules.day_index(enrollment.started_on, today), total_days))
    week_start_index = ((index - 1) // WEEK_DAYS) * WEEK_DAYS + 1

    def view(i: int) -> dict[str, Any]:
        return program_day_out(
            days.get(i),
            index=i,
            day=enrollment.started_on + timedelta(days=i - 1),
            today=today,
            done_map=done_map,
            full_catalog=full_catalog,
        )

    elapsed = max(min(index, total_days), 1)
    return {
        "id": enrollment.id,
        "program": program_summary_out(enrollment.program, locked=False, is_active=enrollment.status == "active"),
        "status": enrollment.status,
        "started_on": enrollment.started_on,
        "day_index": index,
        "percent": rules.percent(index, total_days),
        "assiduity_percent": rules.percent(done_days, elapsed),
        "today": view(index),
        "week": [view(i) for i in range(week_start_index, min(week_start_index + WEEK_DAYS, total_days + 1))],
        "report": enrollment.report,
    }


def challenge_summary_out(challenge: Challenge, *, joined: bool) -> dict[str, Any]:
    body: dict[str, Any] = {
        "id": challenge.id,
        "name": resolve(challenge.name),
        "description": resolve(challenge.description),
        "duration_days": challenge.duration_days,
        "rule_label": rule_label(challenge.rule, resolve(challenge.name)),
        "validation": "manual" if challenge.rule.metric == "manual" else "auto",
        "success_threshold_percent": round_int(float(challenge.success_threshold) * 100),
        "points": challenge.points_completion,
        "joined": joined,
    }
    if challenge.badge:
        body["badge"] = badge_ref(challenge.badge)
    cover = _image(challenge.cover_key)
    if cover:
        body["cover"] = cover
    return body


def participation_out(participation: ChallengeParticipation, *, today: date) -> dict[str, Any]:
    challenge = participation.challenge
    ends_on = participation.started_on + timedelta(days=challenge.duration_days - 1)
    rows = {d.date: d for d in participation.days.all()}
    days = []
    for offset in range(challenge.duration_days):
        current = participation.started_on + timedelta(days=offset)
        row = rows.get(current)
        status = row.status if row else ("upcoming" if current > today else "pending")
        days.append({"date": current, "status": status})
    body: dict[str, Any] = {
        "id": participation.id,
        "challenge": challenge_summary_out(challenge, joined=participation.status == "active"),
        "status": participation.status,
        "started_on": participation.started_on,
        "ends_on": ends_on,
        "success_rate_percent": round_int(float(participation.success_rate) * 100),
        "streak": rules.current_streak({d: r.status for d, r in rows.items()}, today),
        "days": days,
    }
    if participation.status == "active" and participation.started_on <= today <= ends_on:
        body["today"] = challenge_today_out(participation, today=today, row=rows.get(today))
    return body


def challenge_today_out(participation: ChallengeParticipation, *, today: date, row: Any) -> dict[str, Any]:
    challenge = participation.challenge
    rule = challenge.rule
    threshold = float(rule.threshold)
    value = float(row.value) if row and row.value is not None else 0.0
    manual = rule.metric == "manual"
    progress = None if manual or threshold <= 0 else round(min(value / threshold, 1.0), 3)
    label = ""
    if rule.metric == "water_ml":
        label = _("%(value)s L sur %(target)s L") % {
            "value": f"{value / 1000:.1f}".replace(".", ","),
            "target": f"{threshold / 1000:g}".replace(".", ","),
        }
    elif rule.metric == "steps":
        label = _("%(value)s pas sur %(target)s") % {"value": int(value), "target": int(threshold)}
    return {
        "participation_id": participation.id,
        "name": resolve(challenge.name),
        "day_index": rules.day_index(participation.started_on, today),
        "duration_days": challenge.duration_days,
        "today_status": row.status if row else "pending",
        "today_progress": progress,
        "today_label": label,
        "can_check": manual,
    }
