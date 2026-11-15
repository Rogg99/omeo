"""Invalidation du cache du site public (web/) à la publication d'un contenu.

Le site garde en cache 10 min les tarifs, la FAQ et les pages légales (tags « plans », « faq »,
« legal »). Toute écriture sur ces modèles appelle, après validation de la transaction, le webhook
signé du site : POST {WEB_INTERNAL_URL}/hooks/revalidate.

Signature (partagée avec web/src/server/revalidate-signature.ts) :
  X-Omeo-Timestamp : secondes epoch
  X-Omeo-Signature : "sha256=" + HMAC-SHA256(REVALIDATE_SECRET, f"{timestamp}.{corps brut}")
"""

from __future__ import annotations

import hashlib
import hmac
import json
from collections.abc import Callable, Iterable
from typing import Any

from django.apps import apps
from django.db import transaction
from django.db.models.signals import post_delete, post_save

# Modèle → tags du cache du site à invalider
TAGS_BY_MODEL: dict[str, tuple[str, ...]] = {
    "content.FaqItem": ("faq",),
    "accounts.LegalDocument": ("legal",),
    "billing.Plan": ("plans",),
    "billing.QuotaRule": ("plans",),
}


def body_for(tags: Iterable[str]) -> str:
    """Corps JSON compact, trié : le même corps est signé et envoyé."""
    return json.dumps({"tags": sorted(set(tags))}, separators=(",", ":"))


def sign(secret: str, timestamp: str, body: str) -> str:
    digest = hmac.new(secret.encode(), f"{timestamp}.{body}".encode(), hashlib.sha256).hexdigest()
    return f"sha256={digest}"


def _schedule(tags: tuple[str, ...]) -> Callable[..., None]:
    def handler(**_kwargs: Any) -> None:
        from apps.core.tasks import revalidate_web

        transaction.on_commit(lambda: revalidate_web.delay(list(tags)))

    return handler


def connect() -> None:
    """Branche les signaux (appelé depuis CoreConfig.ready)."""
    for label, tags in TAGS_BY_MODEL.items():
        model = apps.get_model(label)
        handler = _schedule(tags)
        post_save.connect(handler, sender=model, weak=False, dispatch_uid=f"web_cache.save.{label}")
        post_delete.connect(handler, sender=model, weak=False, dispatch_uid=f"web_cache.delete.{label}")
