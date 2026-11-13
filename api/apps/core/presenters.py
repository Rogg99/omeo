"""Sorties communes à toutes les applications (images signées)."""

from __future__ import annotations

from typing import Any

from apps.core.storage import presign_download, public_url


def image_from_key(key: str) -> dict[str, Any] | None:
    """Média publié (bucket public) : URL permanente, servie par le CDN."""
    return {"url": public_url(key)} if key else None


def image_out(upload: Any) -> dict[str, Any] | None:
    if upload is None or upload.status != "ready":
        return None
    out: dict[str, Any] = {"url": presign_download(key=upload.storage_key)}
    if upload.width:
        out["width"] = upload.width
    if upload.height:
        out["height"] = upload.height
    return out
