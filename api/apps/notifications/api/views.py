"""Vues minces des notifications : appareils, préférences, centre de notifications."""

from __future__ import annotations

from typing import Any

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.request import Request
from rest_framework.response import Response

from apps.core.pagination import cursor_paginate
from apps.core.views import AppAPIView, validated
from apps.notifications import selectors, services
from apps.notifications import serializers as s


class DevicesView(AppAPIView):
    @extend_schema(operation_id="registerPushDevice", request=s.DeviceSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.DeviceSerializer, request.data)
        services.register_device(
            user=request.user,
            token=data["token"],
            platform=data["platform"],
            app_version=data["app_version"],
            session=getattr(request, "auth_session", None),
        )
        return Response(status=status.HTTP_204_NO_CONTENT)


class DeviceDetailView(AppAPIView):
    @extend_schema(operation_id="unregisterPushDevice")
    def delete(self, request: Request, token: str) -> Response:
        services.unregister_device(user=request.user, token=token)
        return Response(status=status.HTTP_204_NO_CONTENT)


class PreferencesView(AppAPIView):
    @extend_schema(operation_id="getNotificationPreferences")
    def get(self, request: Request) -> Response:
        return Response(s.preferences_out(services.preferences_for(request.user)))

    @extend_schema(operation_id="updateNotificationPreferences", request=s.PreferencesSerializer)
    def put(self, request: Request) -> Response:
        data = validated(s.PreferencesSerializer, request.data)
        return Response(s.preferences_out(services.update_preferences(user=request.user, data=data)))


class NotificationsView(AppAPIView):
    @extend_schema(operation_id="listNotifications")
    def get(self, request: Request) -> Response:
        params = validated(s.ListSerializer, request.query_params)
        queryset = selectors.notifications_for(user=request.user, unread=params["unread"])
        rows, next_cursor = cursor_paginate(request, queryset)
        return Response(
            {
                "results": [s.notification_out(n) for n in rows],
                "next_cursor": next_cursor,
                "unread_count": services.unread_count(request.user),
            }
        )


class MarkReadView(AppAPIView):
    @extend_schema(operation_id="markNotificationsRead", request=s.ReadSerializer)
    def post(self, request: Request) -> Response:
        data = validated(s.ReadSerializer, request.data)
        count = services.mark_read(user=request.user, ids=data.get("ids"), all_=data["all"])
        return Response({"unread_count": count})


class OpenedView(AppAPIView):
    @extend_schema(operation_id="trackNotificationOpened", request=None)
    def post(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        services.track_opened(user=request.user, notification_id=id)
        return Response(status=status.HTTP_204_NO_CONTENT)
