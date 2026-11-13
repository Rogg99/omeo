"""Vues minces de gamification : écran « Mes récompenses », badges, historique des points."""

from __future__ import annotations

from typing import Final

from drf_spectacular.utils import extend_schema
from rest_framework.request import Request
from rest_framework.response import Response

from apps.billing.services import entitlement_for
from apps.core.pagination import cursor_body, cursor_paginate
from apps.core.views import AppAPIView
from apps.gamification import selectors, services
from apps.gamification import serializers as s

NEXT_BADGES: Final = 3


class RewardsView(AppAPIView):
    @extend_schema(operation_id="getRewards")
    def get(self, request: Request) -> Response:
        user = request.user
        stats = services.stats_for(user)
        level, following, percent = services.level_progress(total_points=stats.total_points)
        metrics = selectors.metrics(stats)
        owned = selectors.owned_badges(user=user)
        badges = [s.user_badge_out(b, owned.get(b.pk), metrics) for b in selectors.published_badges()]
        earned = sorted((b for b in badges if b["state"] == "earned"), key=lambda b: b["earned_at"], reverse=True)
        upcoming = sorted((b for b in badges if b["state"] != "earned"), key=lambda b: -b["progress_percent"])
        freeze_allowed = entitlement_for(user).allows("streak_freeze")
        return Response(
            {
                "level": services.level_info(level),
                "next_level": services.level_info(following),
                "total_points": stats.total_points,
                "points_to_next": max(following.min_points - stats.total_points, 0) if following else 0,
                "progress_percent": percent,
                "week_points": services.week_points(user=user),
                "streak": stats.current_streak,
                "best_streak": stats.best_streak,
                "streak_freeze_available": freeze_allowed and stats.streak_freezes_used_week == 0,
                "badges_earned": earned,
                "badges_next": upcoming[:NEXT_BADGES],
            }
        )


class BadgesView(AppAPIView):
    @extend_schema(operation_id="listBadges")
    def get(self, request: Request) -> Response:
        stats = services.stats_for(request.user)
        metrics = selectors.metrics(stats)
        owned = selectors.owned_badges(user=request.user)
        return Response([s.user_badge_out(b, owned.get(b.pk), metrics) for b in selectors.published_badges()])


class PointEventsView(AppAPIView):
    @extend_schema(operation_id="listPointEvents")
    def get(self, request: Request) -> Response:
        rows, next_cursor = cursor_paginate(request, selectors.point_events(user=request.user))
        return Response(cursor_body([s.point_event_out(e) for e in rows], next_cursor))
