"""Back-office du support : file des demandes, fil complet (notes internes comprises), réponses, modèles."""

from __future__ import annotations

from typing import Any, ClassVar

from django.db import transaction
from django.db.models import Max, Q
from django.utils.translation import gettext_noop
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.request import Request
from rest_framework.response import Response

from apps.accounts.models import User
from apps.core import audit
from apps.core.errors import NotFound, ValidationFailed
from apps.core.pagination import page_body, page_paginate
from apps.core.presenters import image_out
from apps.core.views import AdminAPIView, validated
from apps.notifications.services import notify
from apps.support.models import Direction, Priority, ReplyTemplate, Ticket, TicketCategory, TicketMessage, TicketStatus
from apps.support.presenters import ticket_summary_out


def ticket_detail_out(ticket: Ticket) -> dict[str, Any]:
    messages = ticket.messages.select_related("author").prefetch_related("attachments")
    return {
        **ticket_summary_out(ticket),
        "email": ticket.email,
        "user_id": ticket.user_id,
        "assignee": ticket.assignee.email if ticket.assignee else None,
        "priority": ticket.priority,
        "meta": ticket.meta,
        "messages": [
            {
                "id": m.id,
                "direction": m.direction,
                "author": m.author.email if m.author else None,
                "body": m.body,
                "attachments": [image for a in m.attachments.all() if (image := image_out(a))],
                "created_at": m.created_at,
            }
            for m in messages
        ],
    }


def _ticket(ticket_id: Any) -> Ticket:
    ticket = Ticket.objects.select_related("assignee").filter(pk=ticket_id).first()
    if ticket is None:
        raise NotFound()
    return ticket


class TicketsView(AdminAPIView):
    required_permission = "support.view"

    @extend_schema(operation_id="adminListTickets")
    def get(self, request: Request) -> Response:
        params = request.query_params
        queryset = Ticket.objects.select_related("assignee").annotate(
            last_reply_at=Max("messages__created_at", filter=Q(messages__direction=Direction.OUTBOUND))
        )
        for field in ("status", "category"):
            if params.get(field):
                queryset = queryset.filter(**{field: params[field]})
        if params.get("assignee"):
            queryset = queryset.filter(assignee_id=params["assignee"])
        if params.get("q"):
            term = params["q"]
            queryset = queryset.filter(
                Q(number__icontains=term) | Q(email__icontains=term) | Q(subject__icontains=term)
            )
        rows, meta = page_paginate(request, queryset.order_by("-updated_at"))
        return Response(
            page_body(
                [
                    {
                        **ticket_summary_out(t),
                        "email": t.email,
                        "assignee": t.assignee.email if t.assignee else None,
                        "priority": t.priority,
                        "channel": t.channel,
                        "created_at": t.created_at,
                    }
                    for t in rows
                ],
                meta,
            )
        )


class TicketUpdateSerializer(serializers.Serializer[Any]):
    status = serializers.ChoiceField(choices=TicketStatus.choices, required=False)
    assignee_id = serializers.UUIDField(required=False, allow_null=True)
    priority = serializers.ChoiceField(choices=Priority.choices, required=False)
    category = serializers.ChoiceField(choices=TicketCategory.choices, required=False)


class TicketDetailView(AdminAPIView):
    permission_map: ClassVar[dict[str, str] | None] = {"GET": "support.view", "PATCH": "support.reply"}

    @extend_schema(operation_id="adminGetTicket")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        return Response(ticket_detail_out(_ticket(id)))

    @extend_schema(operation_id="adminUpdateTicket", request=TicketUpdateSerializer)
    def patch(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(TicketUpdateSerializer, request.data)
        with transaction.atomic():
            ticket = _ticket(id)
            before = {"status": ticket.status, "assignee_id": str(ticket.assignee_id), "priority": ticket.priority}
            if "assignee_id" in data:
                assignee = (
                    User.objects.filter(pk=data["assignee_id"], is_staff=True).first() if data["assignee_id"] else None
                )
                if data["assignee_id"] and assignee is None:
                    raise ValidationFailed(errors={"assignee_id": [{"code": "not_found", "message": "unknown staff"}]})
                ticket.assignee = assignee
            for field in ("status", "priority", "category"):
                if field in data:
                    setattr(ticket, field, data[field])
            ticket.save()
            audit.record(
                actor=request.user,
                action="support.update",
                target_type="ticket",
                target_id=ticket.pk,
                before=before,
                after={k: str(v) for k, v in data.items()},
                request=request,
            )
        return Response(ticket_detail_out(_ticket(id)))


class ReplySerializer(serializers.Serializer[Any]):
    kind = serializers.ChoiceField(choices=["reply", "internal_note"])
    body = serializers.CharField(min_length=1, max_length=10_000)
    template_id = serializers.UUIDField(required=False)
    set_status = serializers.ChoiceField(choices=TicketStatus.choices, required=False)


class TicketMessagesView(AdminAPIView):
    required_permission = "support.reply"

    @extend_schema(operation_id="adminReplyTicket", request=ReplySerializer)
    def post(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(ReplySerializer, request.data)
        with transaction.atomic():
            ticket = _ticket(id)
            direction = Direction.OUTBOUND if data["kind"] == "reply" else Direction.INTERNAL_NOTE
            TicketMessage.objects.create(ticket=ticket, author=request.user, direction=direction, body=data["body"])
            ticket.status = data.get("set_status") or (
                TicketStatus.WAITING_USER if direction == Direction.OUTBOUND else ticket.status
            )
            ticket.save(update_fields=["status", "updated_at"])
            if direction == Direction.OUTBOUND and ticket.user is not None:
                notify(
                    user=ticket.user,
                    category="support",
                    title=gettext_noop("Réponse du support"),
                    body=gettext_noop("Tu as une nouvelle réponse à ta demande %(number)s."),
                    params={"number": ticket.number},
                    deeplink=f"omeo://support/{ticket.pk}",
                )
        return Response(ticket_detail_out(_ticket(id)), status=status.HTTP_201_CREATED)


class ReplyTemplatesView(AdminAPIView):
    required_permission = "support.view"

    @extend_schema(operation_id="adminListReplyTemplates")
    def get(self, request: Request) -> Response:
        return Response(
            [
                {"id": t.id, "name": t.name, "category": t.category or None, "body": t.body}
                for t in ReplyTemplate.objects.order_by("name")
            ]
        )
