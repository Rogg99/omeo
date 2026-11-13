"""Sorties publiques des programmes et challenges pour l'accueil (`ProgramToday`, `ChallengeToday`)."""

from __future__ import annotations

from datetime import date
from typing import Any

from django.utils.translation import gettext as _

from apps.core.i18n import resolve
from apps.programs import rules
from apps.programs.models import ChallengeParticipation, Enrollment


def program_today_out(enrollment: Enrollment, *, today: date) -> dict[str, Any]:
    """`enrollment` vient de `selectors.enrollment_for_home` (compteurs du jour annotés)."""
    total_days = enrollment.program.weeks * 7
    index = max(1, min(rules.day_index(enrollment.started_on, today), total_days))
    return {
        "enrollment_id": enrollment.id,
        "program_name": resolve(enrollment.program.name),
        "day_index": index,
        "total_days": total_days,
        "percent": rules.percent(index, total_days),
        "tasks_done": int(getattr(enrollment, "tasks_done_today", 0) or 0),
        "tasks_total": int(getattr(enrollment, "tasks_total_today", 0) or 0),
    }


def _progress_label(metric: str, value: float, threshold: float) -> str:
    if metric == "water_ml":
        return _("%(value)s L sur %(target)s L") % {
            "value": f"{value / 1000:.1f}".replace(".", ","),
            "target": f"{threshold / 1000:g}".replace(".", ","),
        }
    if metric == "steps":
        return _("%(value)s pas sur %(target)s") % {"value": int(value), "target": int(threshold)}
    return ""


def challenge_today_out(participation: ChallengeParticipation, *, today: date) -> dict[str, Any]:
    """`participation` vient de `selectors.participations_for_home` (statut et valeur du jour annotés)."""
    challenge = participation.challenge
    rule = challenge.rule
    threshold = float(rule.threshold)
    raw_value = getattr(participation, "today_value", None)
    value = float(raw_value) if raw_value is not None else 0.0
    manual = rule.metric == "manual"
    return {
        "participation_id": participation.id,
        "name": resolve(challenge.name),
        "day_index": rules.day_index(participation.started_on, today),
        "duration_days": challenge.duration_days,
        "today_status": getattr(participation, "today_status", None) or "pending",
        "today_progress": None if manual or threshold <= 0 else round(min(value / threshold, 1.0), 3),
        "today_label": _progress_label(rule.metric, value, threshold),
        "can_check": manual,
    }
