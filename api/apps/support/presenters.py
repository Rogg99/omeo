"""Sorties publiques du support (résumé d'une demande), réutilisées par la fiche utilisateur du back-office."""

from __future__ import annotations

from typing import Any

from apps.support.models import Ticket


def _unread(last_reply: Any, read_at: Any) -> bool:
    return bool(last_reply and (read_at is None or last_reply > read_at))


def ticket_summary_out(ticket: Ticket) -> dict[str, Any]:
    last_reply = getattr(ticket, "last_reply_at", None)
    return {
        "id": ticket.id,
        "number": ticket.number,
        "subject": ticket.subject,
        "category": ticket.category,
        "status": ticket.status,
        "has_unread_reply": bool(
            last_reply and (ticket.user_last_read_at is None or last_reply > ticket.user_last_read_at)
        ),
        "updated_at": ticket.updated_at,
    }
