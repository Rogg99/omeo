"""Sorties publiques d'activity, réutilisables par les autres applications."""

from __future__ import annotations

from typing import Any

from apps.activity.models import Workout
from apps.core.i18n import resolve
from apps.core.presenters import image_from_key


def workout_summary_out(workout: Workout, *, locked: bool, estimated_kcal: int | None = None) -> dict[str, Any]:
    body: dict[str, Any] = {
        "id": workout.id,
        "name": resolve(workout.name),
        "goal": workout.goal,
        "level": workout.level,
        "duration_s": workout.duration_s,
        "exercises_count": int(getattr(workout, "exercises_count", 0)),
        "locked": locked,
    }
    if estimated_kcal is not None:
        body["estimated_kcal"] = estimated_kcal
    cover = image_from_key(workout.cover_key)
    if cover:
        body["cover"] = cover
    return body
