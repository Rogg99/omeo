"""Entrées et sorties d'activity. Valeurs prêtes à afficher, aucun calcul métier ici."""

from __future__ import annotations

from typing import Any, Final

from django.utils.translation import gettext as _
from django.utils.translation import gettext_lazy
from rest_framework import serializers

from apps.activity.models import Activity, ActivityType, Exercise, HealthConnection, Insight, Intensity, Workout
from apps.activity.presenters import workout_summary_out
from apps.core.i18n import resolve
from apps.core.presenters import image_from_key
from apps.core.storage import public_url

GRANTED_TYPES: Final = ["steps", "distance", "active_calories", "workouts", "weight", "heart_rate"]


# ───────────────────────── Entrées ─────────────────────────


class WeightInputSerializer(serializers.Serializer[Any]):
    weight_kg = serializers.DecimalField(max_digits=5, decimal_places=2, min_value=30, max_value=300)
    date = serializers.DateField(required=False)


class WeightRangeSerializer(serializers.Serializer[Any]):
    range = serializers.ChoiceField(choices=["30d", "90d", "1y", "all"], default="90d")


class HealthConnectionInputSerializer(serializers.Serializer[Any]):
    source = serializers.ChoiceField(choices=["health_connect", "apple_health"])
    granted_types = serializers.ListField(child=serializers.ChoiceField(choices=GRANTED_TYPES), max_length=6)


class SyncDaySerializer(serializers.Serializer[Any]):
    date = serializers.DateField()
    steps = serializers.IntegerField(min_value=0, max_value=200_000, required=False)
    distance_m = serializers.IntegerField(min_value=0, max_value=1_000_000, required=False)
    active_kcal = serializers.IntegerField(min_value=0, max_value=20_000, required=False)
    total_burned_kcal = serializers.IntegerField(min_value=0, max_value=30_000, required=False)


class SyncWorkoutSerializer(serializers.Serializer[Any]):
    external_id = serializers.CharField(max_length=128)
    type = serializers.CharField(max_length=40)
    started_at = serializers.DateTimeField()
    duration_s = serializers.IntegerField(min_value=1, max_value=86_400)
    kcal = serializers.IntegerField(min_value=0, max_value=20_000, required=False)
    distance_m = serializers.IntegerField(min_value=0, max_value=1_000_000, required=False)
    avg_hr = serializers.IntegerField(min_value=20, max_value=250, required=False)


class SyncWeightSerializer(serializers.Serializer[Any]):
    measured_at = serializers.DateTimeField()
    weight_kg = serializers.DecimalField(max_digits=5, decimal_places=2, min_value=30, max_value=300)


class HealthSyncSerializer(serializers.Serializer[Any]):
    source = serializers.ChoiceField(choices=["health_connect", "apple_health"])
    days = SyncDaySerializer(many=True, max_length=31)
    workouts = SyncWorkoutSerializer(many=True, required=False, max_length=200)
    weights = SyncWeightSerializer(many=True, required=False, max_length=100)


class ActivityInputSerializer(serializers.Serializer[Any]):
    type = serializers.ChoiceField(choices=ActivityType.choices)
    duration_s = serializers.IntegerField(min_value=60, max_value=43_200)
    intensity = serializers.ChoiceField(choices=Intensity.choices)
    started_at = serializers.DateTimeField(required=False)
    date = serializers.DateField(required=False)
    label = serializers.CharField(max_length=60, required=False, allow_blank=True)


class ActivityListSerializer(serializers.Serializer[Any]):
    to = serializers.DateField(required=False)

    def to_internal_value(self, data: Any) -> Any:
        values = super().to_internal_value(data)
        if data.get("from"):
            values["from"] = serializers.DateField().to_internal_value(data["from"])
        return values


class DayQuerySerializer(serializers.Serializer[Any]):
    date = serializers.DateField(required=False)


class MergeSerializer(serializers.Serializer[Any]):
    into_id = serializers.UUIDField()


class ExerciseFilterSerializer(serializers.Serializer[Any]):
    q = serializers.CharField(max_length=60, required=False)
    muscle = serializers.CharField(max_length=30, required=False)
    level = serializers.ChoiceField(choices=["beginner", "intermediate", "advanced"], required=False)
    equipment = serializers.ChoiceField(choices=["none", "any"], required=False)


class WorkoutFilterSerializer(serializers.Serializer[Any]):
    goal = serializers.ChoiceField(choices=["cardio", "strength", "mobility"], required=False)
    level = serializers.ChoiceField(choices=["beginner", "intermediate", "advanced"], required=False)
    max_minutes = serializers.IntegerField(min_value=1, max_value=600, required=False)


class WorkoutSessionInputSerializer(serializers.Serializer[Any]):
    workout_id = serializers.UUIDField()
    started_at = serializers.DateTimeField()
    ended_at = serializers.DateTimeField()
    completed_steps = serializers.IntegerField(min_value=0, max_value=200)


# ───────────────────────── Sorties ─────────────────────────


READ_TYPE_LABELS: Final[dict[str, Any]] = {
    "steps": gettext_lazy("pas"),
    "distance": gettext_lazy("distance"),
    "active_calories": gettext_lazy("calories"),
    "workouts": gettext_lazy("séances"),
    "weight": gettext_lazy("poids"),
    "heart_rate": gettext_lazy("fréquence cardiaque"),
}


def health_out(connection: HealthConnection | None) -> dict[str, Any]:
    if connection is None:
        return {"connected": False, "source": None, "granted_types": [], "last_sync_at": None}
    labels = ", ".join(str(READ_TYPE_LABELS[t]) for t in connection.granted_types if t in READ_TYPE_LABELS)
    return {
        "connected": True,
        "source": connection.source,
        "granted_types": list(connection.granted_types),
        "read_types_label": _("Données lues : %(types)s") % {"types": labels} if labels else "",
        "last_sync_at": connection.last_sync_at,
    }


def activity_out(activity: Activity) -> dict[str, Any]:
    return {
        "id": activity.id,
        "date": activity.date,
        "type": activity.type,
        "label": activity.label,
        "started_at": activity.started_at,
        "duration_s": activity.duration_s,
        "intensity": activity.intensity or None,
        "kcal": activity.kcal,
        "distance_m": activity.distance_m,
        "avg_hr": activity.avg_hr,
        "source": activity.source,
        "editable": activity.source == "manual",
    }


def merge_out(manual: Activity, imported: Activity) -> dict[str, Any]:
    return {
        "manual_id": manual.id,
        "imported_id": imported.id,
        "message": _("Cette activité recouvre une séance importée. Fusionner pour ne pas la compter deux fois ?"),
    }


def exercise_summary_out(exercise: Exercise, *, locked: bool) -> dict[str, Any]:
    body: dict[str, Any] = {
        "id": exercise.id,
        "name": resolve(exercise.name),
        "muscles": list(exercise.muscles),
        "level": exercise.level,
        "equipment": list(exercise.equipment),
        "locked": locked,
    }
    thumbnail = image_from_key(exercise.thumbnail_key)
    if thumbnail:
        body["thumbnail"] = thumbnail
    return body


def exercise_detail_out(exercise: Exercise) -> dict[str, Any]:
    video: dict[str, Any] = {
        "hls_url": public_url(exercise.video_key),
        "subtitles": [{"locale": locale, "url": public_url(key)} for locale, key in sorted(exercise.subtitles.items())],
    }
    poster = image_from_key(exercise.thumbnail_key)
    if poster:
        video["poster"] = poster
    if exercise.video_duration_s:
        video["duration_s"] = exercise.video_duration_s
    return {
        **exercise_summary_out(exercise, locked=False),
        "instructions": resolve(exercise.instructions),
        "video": video,
    }


def workout_detail_out(workout: Workout, *, downloadable: bool, estimated_kcal: int) -> dict[str, Any]:
    return {
        **workout_summary_out(workout, locked=False, estimated_kcal=estimated_kcal),
        "description": resolve(workout.description),
        "downloadable": downloadable,
        "steps": [
            {
                "order": step.order,
                "exercise": exercise_detail_out(step.exercise),
                "mode": step.mode,
                "duration_s": step.duration_s,
                "reps": step.reps,
                "rest_s": step.rest_s,
            }
            for step in workout.steps.all()
        ],
    }


def insight_out(insight: Insight) -> dict[str, Any]:
    return {
        "id": insight.id,
        "week_start": insight.week_start,
        "kind": insight.kind,
        "message": resolve(insight.message),
        "data": insight.data,
    }
