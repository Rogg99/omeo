"""Vues minces d'activity : poids, santé connectée, activités, entraînement, analyses croisées."""

from __future__ import annotations

from datetime import timedelta
from typing import Any, ClassVar, Final

from django.conf import settings
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import BasePermission, IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from apps.accounts.presenters import targets_out
from apps.activity import selectors, services, views_data
from apps.activity import serializers as s
from apps.activity.presenters import workout_summary_out
from apps.billing.services import entitlement_for
from apps.core.errors import NotFound, ValidationFailed
from apps.core.idempotency import idempotent
from apps.core.localtime import local_today
from apps.core.pagination import cursor_body, cursor_paginate
from apps.core.permissions import RequiresFeature, require_feature
from apps.core.rewards import collect_rewards
from apps.core.storage import presign_download
from apps.core.views import AppAPIView, validated
from apps.nutrition import selectors as nutrition_selectors
from apps.nutrition import services as nutrition
from apps.nutrition.constants import nutrition_constants
from apps.nutrition.presenters import day_summary_out

FULL_CATALOG: Final = "full_catalog"
MAX_RANGE_DAYS: Final = 92


def _full_catalog(user: Any) -> bool:
    return entitlement_for(user).allows(FULL_CATALOG)


# ───────────────────────── Poids ─────────────────────────


class WeightsView(AppAPIView):
    @extend_schema(operation_id="getWeights")
    def get(self, request: Request) -> Response:
        params = validated(s.WeightRangeSerializer, request.query_params)
        return Response(
            views_data.weight_overview(user=request.user, range_key=params["range"], today=local_today(request.user))
        )

    @extend_schema(operation_id="addWeight", request=s.WeightInputSerializer)
    @idempotent
    def post(self, request: Request) -> Response:
        data = validated(s.WeightInputSerializer, request.data)
        with collect_rewards() as rewards:
            services.add_weight(user=request.user, weight_kg=data["weight_kg"], day=data.get("date"))
        today = local_today(request.user)
        body = {
            "overview": views_data.weight_overview(user=request.user, range_key="90d", today=today),
            "targets": targets_out(nutrition_selectors.target_on(user=request.user, day=today)),
            "rewards": rewards.as_dict(),
        }
        return Response(body, status=status.HTTP_201_CREATED)


class WeightDetailView(AppAPIView):
    @extend_schema(operation_id="deleteWeight")
    def delete(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        services.delete_weight(user=request.user, entry_id=id)
        return Response(views_data.weight_overview(user=request.user, range_key="90d", today=local_today(request.user)))


# ───────────────────────── Santé connectée ─────────────────────────


class HealthConnectionView(AppAPIView):
    @extend_schema(operation_id="setHealthConnection", request=s.HealthConnectionInputSerializer)
    def put(self, request: Request) -> Response:
        data = validated(s.HealthConnectionInputSerializer, request.data)
        connection = services.set_health_connection(
            user=request.user, source=data["source"], granted_types=data["granted_types"]
        )
        return Response(s.health_out(connection))

    @extend_schema(operation_id="deleteHealthConnection")
    def delete(self, request: Request) -> Response:
        services.delete_health_connection(user=request.user)
        return Response(status=status.HTTP_204_NO_CONTENT)


class HealthSyncView(AppAPIView):
    @extend_schema(operation_id="syncHealth", request=s.HealthSyncSerializer)
    @idempotent
    def post(self, request: Request) -> Response:
        data = validated(s.HealthSyncSerializer, request.data)
        with collect_rewards() as rewards:
            result = services.sync_health(
                user=request.user,
                source=data["source"],
                days=data["days"],
                workouts=data.get("workouts", []),
                weights=data.get("weights", []),
            )
        c = nutrition_constants()
        return Response(
            {
                "days": [day_summary_out(d, c=c) for d in result.days],
                "merge_suggestions": [s.merge_out(m, i) for m, i in result.merge_suggestions],
                "rewards": rewards.as_dict(),
                "last_sync_at": result.last_sync_at,
            }
        )


# ───────────────────────── Activités ─────────────────────────


def _activity_write(write: services.ActivityWrite, rewards: dict[str, Any]) -> dict[str, Any]:
    return {
        "activity": s.activity_out(write.activity),
        "day": day_summary_out(write.day, c=nutrition_constants()),
        "merge_suggestion": s.merge_out(write.activity, write.merge_with) if write.merge_with else None,
        "rewards": rewards,
    }


class ActivityOverviewView(AppAPIView):
    @extend_schema(operation_id="getActivityOverview")
    def get(self, request: Request) -> Response:
        params = validated(s.DayQuerySerializer, request.query_params)
        day = nutrition.resolve_day(user=request.user, day=params.get("date"))
        return Response(
            views_data.activity_overview(
                user=request.user, day=day, c=nutrition_constants(), locked=not _full_catalog(request.user)
            )
        )


class ActivitiesView(AppAPIView):
    @extend_schema(operation_id="listActivities")
    def get(self, request: Request) -> Response:
        params = validated(s.ActivityListSerializer, request.query_params)
        queryset = selectors.activities_for(user=request.user)
        start, end = params.get("from"), params.get("to")
        if start and end and (end < start or end - start > timedelta(days=MAX_RANGE_DAYS)):
            raise ValidationFailed(errors={"to": [{"code": "invalid_range", "message": "max 92 days"}]})
        if start:
            queryset = queryset.filter(date__gte=start)
        if end:
            queryset = queryset.filter(date__lte=end)
        rows, next_cursor = cursor_paginate(request, queryset, order_field="started_at")
        return Response(cursor_body([s.activity_out(a) for a in rows], next_cursor))

    @extend_schema(operation_id="createActivity", request=s.ActivityInputSerializer)
    @idempotent
    def post(self, request: Request) -> Response:
        data = validated(s.ActivityInputSerializer, request.data)
        with collect_rewards() as rewards:
            write = services.create_activity(user=request.user, data=data)
        return Response(_activity_write(write, rewards.as_dict()), status=status.HTTP_201_CREATED)


class ActivityDetailView(AppAPIView):
    @extend_schema(operation_id="updateActivity", request=s.ActivityInputSerializer)
    def patch(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(s.ActivityInputSerializer, request.data)
        with collect_rewards() as rewards:
            write = services.update_activity(user=request.user, activity_id=id, data=data)
        return Response(_activity_write(write, rewards.as_dict()))

    @extend_schema(operation_id="deleteActivity")
    def delete(self, request: Request, id: Any) -> Response:  # noqa: A002
        summary = services.delete_activity(user=request.user, activity_id=id)
        return Response({"day": day_summary_out(summary, c=nutrition_constants())})


class ActivityMergeView(AppAPIView):
    @extend_schema(operation_id="mergeActivity", request=s.MergeSerializer)
    def post(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(s.MergeSerializer, request.data)
        with collect_rewards() as rewards:
            write = services.merge_activity(user=request.user, activity_id=id, into_id=data["into_id"])
        return Response(_activity_write(write, rewards.as_dict()))


class InsightsView(AppAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, RequiresFeature("insights")]

    @extend_schema(operation_id="listInsights")
    def get(self, request: Request) -> Response:
        rows, next_cursor = cursor_paginate(request, selectors.insights_for(user=request.user))
        return Response(cursor_body([s.insight_out(i) for i in rows], next_cursor))


# ───────────────────────── Entraînement ─────────────────────────


class ExercisesView(AppAPIView):
    @extend_schema(operation_id="listExercises")
    def get(self, request: Request) -> Response:
        params = validated(s.ExerciseFilterSerializer, request.query_params)
        queryset = selectors.exercises(
            q=params.get("q"), muscle=params.get("muscle"), level=params.get("level"), equipment=params.get("equipment")
        )
        full = _full_catalog(request.user)
        rows, next_cursor = cursor_paginate(request, queryset)
        return Response(
            cursor_body([s.exercise_summary_out(e, locked=not (full or e.is_free)) for e in rows], next_cursor)
        )


class ExerciseDetailView(AppAPIView):
    conditional_entitlements: ClassVar[dict[str, str]] = {"GET": FULL_CATALOG}

    @extend_schema(operation_id="getExercise")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002
        exercise = selectors.exercise(exercise_id=id)
        if exercise is None:
            raise NotFound()
        if not exercise.is_free:
            require_feature(request.user, FULL_CATALOG)
        return Response(s.exercise_detail_out(exercise))


class WorkoutsView(AppAPIView):
    @extend_schema(operation_id="listWorkouts")
    def get(self, request: Request) -> Response:
        params = validated(s.WorkoutFilterSerializer, request.query_params)
        queryset = selectors.workouts(
            goal=params.get("goal"), level=params.get("level"), max_minutes=params.get("max_minutes")
        )
        full = _full_catalog(request.user)
        rows, next_cursor = cursor_paginate(request, queryset)
        return Response(
            cursor_body([workout_summary_out(w, locked=not (full or w.is_free)) for w in rows], next_cursor)
        )


class WorkoutDetailView(AppAPIView):
    conditional_entitlements: ClassVar[dict[str, str]] = {"GET": FULL_CATALOG}

    @extend_schema(operation_id="getWorkout")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002
        workout = selectors.workout(workout_id=id)
        if workout is None:
            raise NotFound()
        if not workout.is_free:
            require_feature(request.user, FULL_CATALOG)
        weight = float(request.user.profile.current_weight_kg)  # type: ignore[union-attr]
        return Response(
            s.workout_detail_out(
                workout,
                downloadable=entitlement_for(request.user).allows("offline_workouts"),
                estimated_kcal=views_data.estimated_kcal(workout, weight_kg=weight),
            )
        )


class WorkoutDownloadView(AppAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, RequiresFeature("offline_workouts")]

    @extend_schema(operation_id="getWorkoutDownload")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002
        workout = selectors.workout(workout_id=id)
        if workout is None:
            raise NotFound()
        ttl = settings.DOWNLOAD_URL_TTL_SECONDS
        files = [
            {
                "exercise_id": step.exercise_id,
                "url": presign_download(key=step.exercise.download_key, ttl=ttl),
                "size": step.exercise.download_size or 0,
            }
            for step in workout.steps.all()
            if step.exercise.download_key
        ]
        unique = list({f["exercise_id"]: f for f in files}.values())
        return Response({"files": unique, "expires_at": timezone.now() + timedelta(seconds=ttl)})


class WorkoutSessionsView(AppAPIView):
    @extend_schema(operation_id="completeWorkoutSession", request=s.WorkoutSessionInputSerializer)
    @idempotent
    def post(self, request: Request) -> Response:
        data = validated(s.WorkoutSessionInputSerializer, request.data)
        with collect_rewards() as rewards:
            write = services.complete_workout_session(
                user=request.user,
                workout_id=data["workout_id"],
                started_at=data["started_at"],
                ended_at=data["ended_at"],
                completed_steps=data["completed_steps"],
            )
        session = write.session
        return Response(
            {
                "id": session.id,
                "kcal": session.kcal,
                "duration_s": session.duration_s,
                "completed": session.completed,
                "day": day_summary_out(write.day, c=nutrition_constants()),
                "rewards": rewards.as_dict(),
            },
            status=status.HTTP_201_CREATED,
        )
