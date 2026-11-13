"""Vues minces du support : demandes (connecté ou public avec captcha), fil de discussion, exports de données."""

from __future__ import annotations

from typing import Any, ClassVar

from django.db.models import Max, Q
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import AllowAny, BasePermission, IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.throttling import BaseThrottle

from apps.core.audit import client_ip
from apps.core.captcha import verify_turnstile
from apps.core.idempotency import idempotent
from apps.core.permissions import RequiresVerifiedEmail
from apps.core.presenters import image_out
from apps.core.throttles import PublicFormThrottle, UserThrottle
from apps.core.views import AppAPIView, validated
from apps.support import serializers as s
from apps.support import services
from apps.support.models import DataExport, Direction, Ticket


class TicketCreateView(AppAPIView):
    """Authentification facultative (contrat : `bearer` ou rien). Sans compte : email et captcha obligatoires."""

    permission_classes: ClassVar[list[type[BasePermission]]] = [AllowAny]

    def get_throttles(self) -> list[BaseThrottle]:
        if self.request.user and self.request.user.is_authenticated:
            return [UserThrottle()]
        return [PublicFormThrottle()]

    @extend_schema(operation_id="createTicket", request=s.TicketInputSerializer)
    @idempotent
    def post(self, request: Request) -> Response:
        data = validated(s.TicketInputSerializer, request.data)
        user = request.user if request.user.is_authenticated else None
        if user is None:
            verify_turnstile(data.get("captcha"), remote_ip=client_ip(request))
        ticket = services.create_ticket(
            user=user,
            category=data["category"],
            subject=data["subject"],
            message=data["message"],
            email=data.get("email"),
            name=data["name"],
            attachment_ids=data["attachment_ids"],
            meta=data["meta"],
            channel="app" if user else "web",
        )
        return Response({"number": ticket.number}, status=status.HTTP_201_CREATED)


class MyTicketsView(AppAPIView):
    @extend_schema(operation_id="listMyTickets")
    def get(self, request: Request) -> Response:
        tickets = (
            Ticket.objects.filter(user=request.user)
            .annotate(last_reply_at=Max("messages__created_at", filter=Q(messages__direction=Direction.OUTBOUND)))
            .order_by("-updated_at")
        )
        return Response([s.ticket_summary_out(t) for t in tickets])


class MyTicketDetailView(AppAPIView):
    @extend_schema(operation_id="getMyTicket")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        ticket = services.own_ticket(user=request.user, ticket_id=id)
        messages = ticket.messages.exclude(direction=Direction.INTERNAL_NOTE).prefetch_related("attachments")
        body = {
            **s.ticket_summary_out(ticket),
            "email": ticket.email,
            "user_id": ticket.user_id,
            "priority": ticket.priority,
            "meta": ticket.meta,
            "messages": [
                {
                    "id": m.id,
                    "direction": m.direction,
                    "author": None,
                    "body": m.body,
                    "attachments": [image for a in m.attachments.all() if (image := image_out(a))],
                    "created_at": m.created_at,
                }
                for m in messages
            ],
        }
        services.mark_ticket_read(ticket)
        return Response(body)


class ExportsView(AppAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, RequiresVerifiedEmail]
    email_verified_methods: ClassVar[set[str]] = {"POST"}

    @extend_schema(operation_id="requestDataExport", request=None)
    def post(self, request: Request) -> Response:
        export = services.request_export(user=request.user)
        return Response(s.export_out(export), status=status.HTTP_202_ACCEPTED)

    @extend_schema(operation_id="listDataExports")
    def get(self, request: Request) -> Response:
        exports = DataExport.objects.filter(user=request.user).order_by("-requested_at")
        return Response([s.export_out(e) for e in exports])
