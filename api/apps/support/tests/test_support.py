"""Support : demandes connectées et publiques, fil sans notes internes, exports RGPD (archive, délai, expiration)."""

from __future__ import annotations

import io
import json
import uuid
import zipfile
from collections.abc import Callable
from datetime import timedelta
from typing import Any

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.core import storage
from apps.support import services
from apps.support.models import DataExport, Direction, Ticket, TicketMessage
from conftest import login_client

pytestmark = pytest.mark.django_db

TICKET = {"category": "question", "subject": "Analyse photo", "message": "Ma photo n'est pas reconnue, pourquoi ?"}


def post_ticket(client: APIClient, **extra: Any) -> Any:
    return client.post(
        "/api/v1/support/tickets", {**TICKET, **extra}, format="json", HTTP_IDEMPOTENCY_KEY=str(uuid.uuid4())
    )


class TestTickets:
    def test_connected_user(self, api: APIClient, user: User) -> None:
        response = post_ticket(api, meta={"app_version": "1.0.0", "os": "android 15"})
        assert response.status_code == 201
        ticket = Ticket.objects.get(number=response.json()["number"])
        assert ticket.user == user
        assert ticket.email == user.email
        assert ticket.meta["app_version"] == "1.0.0"

    def test_numbers_are_sequential(self, api: APIClient) -> None:
        first = post_ticket(api).json()["number"]
        second = post_ticket(api).json()["number"]
        assert int(second.split("-")[1]) == int(first.split("-")[1]) + 1

    def test_anonymous_needs_email(self, anon: APIClient, reference: None) -> None:
        assert post_ticket(anon).status_code == 400
        response = post_ticket(anon, email="visiteur@example.com", captcha="token")
        assert response.status_code == 201
        assert Ticket.objects.get().channel == "web"

    def test_thread_hides_internal_notes(self, api: APIClient, user: User) -> None:
        number = post_ticket(api).json()["number"]
        ticket = Ticket.objects.get(number=number)
        TicketMessage.objects.create(ticket=ticket, direction=Direction.INTERNAL_NOTE, body="Note interne")
        TicketMessage.objects.create(ticket=ticket, direction=Direction.OUTBOUND, body="Bonjour Awa")
        assert api.get("/api/v1/me/tickets").json()[0]["has_unread_reply"] is True
        detail = api.get(f"/api/v1/me/tickets/{ticket.pk}").json()
        assert [m["direction"] for m in detail["messages"]] == ["inbound", "outbound"]
        assert api.get("/api/v1/me/tickets").json()[0]["has_unread_reply"] is False

    def test_other_users_ticket_404(self, api: APIClient, make_user: Callable[..., User]) -> None:
        ticket_id = Ticket.objects.get(number=post_ticket(api).json()["number"]).pk
        assert login_client(make_user()).get(f"/api/v1/me/tickets/{ticket_id}").status_code == 404


class TestExports:
    @pytest.fixture(autouse=True)
    def fake_storage(self, monkeypatch: pytest.MonkeyPatch) -> dict[str, bytes]:
        stored: dict[str, bytes] = {}
        monkeypatch.setattr(storage, "put_bytes", lambda **kw: stored.__setitem__(kw["key"], kw["data"]))
        monkeypatch.setattr(storage, "presign_download", lambda **kw: f"https://s3.test/{kw['key']}")
        monkeypatch.setattr(storage, "delete", lambda **kw: stored.pop(kw["key"], None))
        return stored

    def test_export_built_with_all_sections(self, api: APIClient, fake_storage: dict[str, bytes]) -> None:
        response = api.post("/api/v1/me/exports")
        assert response.status_code == 202
        export = api.get("/api/v1/me/exports").json()[0]
        assert export["status"] == "ready"
        assert export["download_url"].startswith("https://s3.test/exports/")
        archive = zipfile.ZipFile(io.BytesIO(next(iter(fake_storage.values()))))
        data = json.loads(archive.read("omeo-export.json"))
        assert {"account", "consents", "meals", "water", "weights", "activities"} <= set(data)
        assert data["account"][0]["first_name"] == "Awa"

    def test_one_export_per_day(self, api: APIClient) -> None:
        api.post("/api/v1/me/exports")
        response = api.post("/api/v1/me/exports")
        assert response.status_code == 429
        assert response.json()["code"] == "rate_limited"

    def test_requires_verified_email(self, make_user: Callable[..., User]) -> None:
        client = login_client(make_user(verified=False))
        assert client.post("/api/v1/me/exports").status_code == 403
        assert client.get("/api/v1/me/exports").status_code == 200

    def test_expiration(self, api: APIClient, user: User, fake_storage: dict[str, bytes]) -> None:
        api.post("/api/v1/me/exports")
        DataExport.objects.filter(user=user).update(expires_at=timezone.now() - timedelta(minutes=1))
        assert services.expire_exports() == 1
        assert not fake_storage
        assert api.get("/api/v1/me/exports").json()[0]["download_url"] is None
