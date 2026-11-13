"""Sorties communes à toutes les applications (images signées)."""

from __future__ import annotations

from typing import Any

from apps.core.models import ApprovalRequest
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


def staff_name(user: Any) -> str | None:
    return user.email if user is not None else None


def approval_out(approval: ApprovalRequest) -> dict[str, Any]:
    return {
        "id": approval.id,
        "kind": approval.kind,
        "domain": approval.domain,
        "status": approval.status,
        "summary": f"{approval.kind} {approval.target_type}:{approval.target_id}",
        "target_type": approval.target_type,
        "target_id": approval.target_id,
        "diff": approval.diff,
        "reason": approval.reason or None,
        "requested_by": staff_name(approval.requested_by),
        "decided_by": staff_name(approval.decided_by),
        "decision_comment": approval.decision_comment or None,
        "created_at": approval.created_at,
        "decided_at": approval.decided_at,
        "expires_at": approval.expires_at,
    }
