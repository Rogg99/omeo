"""Vérification serveur du captcha Cloudflare Turnstile sur les formulaires publics."""

from __future__ import annotations

from typing import Final

import httpx
from django.conf import settings

from apps.core.errors import ValidationFailed

VERIFY_URL: Final = "https://challenges.cloudflare.com/turnstile/v0/siteverify"
TIMEOUT_S: Final = 5.0


def verify_turnstile(token: str | None, *, remote_ip: str | None) -> None:
    secret: str = settings.TURNSTILE_SECRET_KEY
    if not secret:
        if settings.ENV == "production":
            raise RuntimeError("TURNSTILE_SECRET_KEY is required in production")
        return
    if not token:
        raise ValidationFailed(errors={"captcha": [{"code": "required", "message": "captcha required"}]})
    data = {"secret": secret, "response": token}
    if remote_ip:
        data["remoteip"] = remote_ip
    try:
        response = httpx.post(VERIFY_URL, data=data, timeout=TIMEOUT_S)
        ok = response.status_code == 200 and bool(response.json().get("success"))
    except httpx.HTTPError:
        ok = False
    if not ok:
        raise ValidationFailed(errors={"captcha": [{"code": "invalid", "message": "captcha failed"}]})
