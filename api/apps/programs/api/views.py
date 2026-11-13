"""Vues minces des programmes et challenges."""

from __future__ import annotations

from datetime import date, timedelta
from typing import Any, ClassVar, Final

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import BasePermission, IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from apps.billing.services import entitlement_for
from apps.core.errors import NotFound
from apps.core.localtime import local_today
from apps.core.permissions import RequiresFeature
from apps.core.rewards import collect_rewards
from apps.core.views import AppAPIView, validated
from apps.gamification.services import badge_ref
from apps.programs import selectors, services
from apps.programs import serializers as s
from apps.programs.models import Enrollment, TaskCompletion

WEEK_DAYS: Final = 7
PREVIEW_DAYS: Final = 3


def enrollment_body(enrollment: Enrollment, *, user: Any, today: date) -> dict[str, Any]:
    total = enrollment.program.weeks * WEEK_DAYS
    index = max(1, min((today - enrollment.started_on).days + 1, total))
    week_start = ((index - 1) // WEEK_DAYS) * WEEK_DAYS + 1
    indexes = list(range(week_start, min(week_start + WEEK_DAYS, total + 1)))
    start = enrollment.started_on + timedelta(days=week_start - 1)
    done_days = (
        TaskCompletion.objects.filter(enrollment=enrollment, done=True).values("date").distinct().count()
    )
    return s.enrollment_out(
        enrollment,
        today=today,
        days=selectors.program_days(user=user, program=enrollment.program, indexes=indexes),
        done_map=selectors.completions(enrollment=enrollment, start=start, end=start + timedelta(days=WEEK_DAYS)),
        full_catalog=entitlement_for(user).allows("full_catalog"),
        done_days=done_days,
    )


class ProgramsView(AppAPIView):
    @extend_schema(operation_id="listPrograms")
    def get(self, request: Request) -> Response:
        params = validated(s.ProgramFilterSerializer, request.query_params)
        locked = not entitlement_for(request.user).allows("programs")
        active = services.active_enrollment(request.user)
        return Response(
            [
                s.program_summary_out(p, locked=locked, is_active=bool(active and active.program_id == p.pk))
                for p in selectors.programs(goal=params.get("goal"))
            ]
        )


class ProgramDetailView(AppAPIView):
    @extend_schema(operation_id="getProgram")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        program = selectors.program(program_id=id)
        if program is None:
            raise NotFound()
        user = request.user
        today = local_today(user)
        locked = not entitlement_for(user).allows("programs")
        active = services.active_enrollment(user)
        days = selectors.program_days(user=user, program=program, indexes=list(range(1, PREVIEW_DAYS + 1)))
        preview = [
            s.program_day_out(
                days.get(i),
                index=i,
                day=today + timedelta(days=i - 1),
                today=today,
                done_map={},
                full_catalog=not locked,
            )
            for i in range(1, PREVIEW_DAYS + 1)
        ]
        rewards: dict[str, Any] = {"points": program.points}
        if program.badge:
            rewards["badge"] = badge_ref(program.badge)
        return Response(
            {
                **s.program_summary_out(program, locked=locked, is_active=bool(active and active.program_id == program.pk)),
                "days_preview": preview,
                "rewards": rewards,
            }
        )


class EnrollView(AppAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, RequiresFeature("programs")]

    @extend_schema(operation_id="enrollProgram", request=s.EnrollSerializer)
    def post(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(s.EnrollSerializer, request.data or {})
        enrollment = services.enroll(user=request.user, program_id=id, replace=data["replace"])
        body = enrollment_body(enrollment, user=request.user, today=local_today(request.user))
        return Response(body, status=status.HTTP_201_CREATED)


class ActiveProgramView(AppAPIView):
    @extend_schema(operation_id="getActiveProgram")
    def get(self, request: Request) -> Response:
        params = validated(s.DayQuerySerializer, request.query_params)
        enrollment = services.active_enrollment(request.user)
        if enrollment is None:
            raise NotFound()
        today = params.get("date") or local_today(request.user)
        return Response(enrollment_body(enrollment, user=request.user, today=today))

    @extend_schema(operation_id="quitProgram")
    def delete(self, request: Request) -> Response:
        services.quit_program(user=request.user)
        return Response(status=status.HTTP_204_NO_CONTENT)


class ProgramTaskView(AppAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, RequiresFeature("programs")]

    @extend_schema(operation_id="checkProgramTask", request=s.CheckTaskSerializer)
    def put(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(s.CheckTaskSerializer, request.data)
        with collect_rewards() as rewards:
            enrollment = services.check_task(user=request.user, task_id=id, done=data["done"], day=data.get("date"))
        body = enrollment_body(enrollment, user=request.user, today=local_today(request.user))
        return Response({"enrollment": body, "rewards": rewards.as_dict()})


class ChallengesView(AppAPIView):
    @extend_schema(operation_id="listChallenges")
    def get(self, request: Request) -> Response:
        joined = selectors.active_challenge_ids(user=request.user)
        return Response([s.challenge_summary_out(c, joined=c.pk in joined) for c in selectors.challenges()])


class ChallengeDetailView(AppAPIView):
    @extend_schema(operation_id="getChallenge")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002
        challenge = selectors.challenge(challenge_id=id)
        if challenge is None:
            raise NotFound()
        joined = challenge.pk in selectors.active_challenge_ids(user=request.user)
        return Response(s.challenge_summary_out(challenge, joined=joined))


class JoinChallengeView(AppAPIView):
    @extend_schema(operation_id="joinChallenge", request=None)
    def post(self, request: Request, id: Any) -> Response:  # noqa: A002
        with collect_rewards():
            participation = services.join_challenge(user=request.user, challenge_id=id)
        row = selectors.participations(user=request.user, status=None).get(pk=participation.pk)
        return Response(s.participation_out(row, today=local_today(request.user)), status=status.HTTP_201_CREATED)


class MyChallengesView(AppAPIView):
    @extend_schema(operation_id="listMyChallenges")
    def get(self, request: Request) -> Response:
        params = validated(s.ParticipationFilterSerializer, request.query_params)
        today = local_today(request.user)
        rows = selectors.participations(user=request.user, status=params.get("status"))
        return Response([s.participation_out(p, today=today) for p in rows])


class MyChallengeDetailView(AppAPIView):
    @extend_schema(operation_id="getMyChallenge")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002
        row = selectors.participations(user=request.user, status=None).filter(pk=id).first()
        if row is None:
            raise NotFound()
        return Response(s.participation_out(row, today=local_today(request.user)))

    @extend_schema(operation_id="leaveChallenge")
    def delete(self, request: Request, id: Any) -> Response:  # noqa: A002
        services.leave_challenge(user=request.user, participation_id=id)
        return Response(status=status.HTTP_204_NO_CONTENT)


class ChallengeDayView(AppAPIView):
    @extend_schema(operation_id="checkChallengeDay", request=s.CheckDaySerializer)
    def put(self, request: Request, id: Any, date: date) -> Response:  # noqa: A002
        data = validated(s.CheckDaySerializer, request.data)
        with collect_rewards() as rewards:
            services.check_challenge_day(user=request.user, participation_id=id, day=date, done=data["done"])
        row = selectors.participations(user=request.user, status=None).get(pk=id)
        return Response({"participation": s.participation_out(row, today=local_today(request.user)), "rewards": rewards.as_dict()})
