"""
Accès au stockage objet compatible S3 (MinIO en dev, S3 ou R2 en prod).

Deux buckets :
- privé  (STORAGES["default"]) : fichiers des utilisateurs, accessibles uniquement par URL signée et temporaire ;
- public (STORAGES["public"])  : médias des contenus publiés, en lecture publique.

Les clients (mobile, admin) téléversent directement vers le stockage par URL présignée : le fichier
ne transite jamais par l'API. La signature SigV4 inclut le Host. On signe donc avec l'adresse PUBLIQUE
(S3_PUBLIC_ENDPOINT_URL), tandis que les opérations serveur (lecture, vérification, suppression) passent
par l'adresse interne (S3_ENDPOINT_URL). Signer ne nécessite aucun appel réseau.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from functools import cache
from typing import TYPE_CHECKING, Literal

import boto3
from botocore.config import Config
from django.conf import settings

if TYPE_CHECKING:
    from mypy_boto3_s3 import S3Client

Bucket = Literal["private", "public"]

ALLOWED_IMAGE_TYPES: dict[str, str] = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
    "image/heic": "heic",
}


@dataclass(frozen=True, slots=True)
class PresignedUpload:
    key: str
    url: str
    method: Literal["PUT"]
    headers: dict[str, str]
    expires_at: datetime


def _bucket_name(bucket: Bucket) -> str:
    return settings.S3_PRIVATE_BUCKET if bucket == "private" else settings.S3_PUBLIC_BUCKET


def _make_client(endpoint_url: str | None) -> S3Client:
    return boto3.client(
        "s3",
        endpoint_url=endpoint_url,
        region_name=settings.S3_REGION,
        aws_access_key_id=settings.S3_ACCESS_KEY_ID,
        aws_secret_access_key=settings.S3_SECRET_ACCESS_KEY,
        config=Config(signature_version="s3v4", s3={"addressing_style": "path"}, retries={"mode": "standard"}),
    )


@cache
def internal_client() -> S3Client:
    """Client des opérations serveur (réseau interne)."""
    return _make_client(settings.S3_ENDPOINT_URL)


@cache
def signing_client() -> S3Client:
    """Client utilisé uniquement pour signer des URL destinées aux clients."""
    return _make_client(settings.S3_PUBLIC_ENDPOINT_URL)


def build_key(*, prefix: str, owner_id: uuid.UUID | str | None, extension: str) -> str:
    """Clé non devinable, rangée par préfixe et propriétaire : `meal_photo/<owner>/<uuid>.jpg`."""
    owner = str(owner_id) if owner_id else "shared"
    return f"{prefix.strip('/')}/{owner}/{uuid.uuid4().hex}.{extension.lstrip('.')}"


def presign_upload(*, key: str, content_type: str, size: int, bucket: Bucket = "private") -> PresignedUpload:
    """
    URL de PUT présignée. Content-Type et Content-Length sont signés : le client ne peut téléverser
    ni un autre type, ni une autre taille que ceux déclarés. Le type réel est revérifié après réception.
    """
    if size <= 0:
        raise ValueError("size must be positive")
    ttl = settings.UPLOAD_URL_TTL_SECONDS
    url = signing_client().generate_presigned_url(
        "put_object",
        Params={
            "Bucket": _bucket_name(bucket),
            "Key": key,
            "ContentType": content_type,
            "ContentLength": size,
        },
        ExpiresIn=ttl,
        HttpMethod="PUT",
    )
    return PresignedUpload(
        key=key,
        url=url,
        method="PUT",
        headers={"Content-Type": content_type},
        expires_at=datetime.now(UTC) + timedelta(seconds=ttl),
    )


def presign_download(*, key: str, filename: str | None = None, ttl: int | None = None) -> str:
    """URL de lecture temporaire d'un fichier privé."""
    params: dict[str, str] = {"Bucket": settings.S3_PRIVATE_BUCKET, "Key": key}
    if filename:
        params["ResponseContentDisposition"] = f'attachment; filename="{filename}"'
    return signing_client().generate_presigned_url(
        "get_object", Params=params, ExpiresIn=ttl or settings.DOWNLOAD_URL_TTL_SECONDS
    )


def public_url(key: str) -> str:
    """URL permanente d'un média publié (bucket public, servi par CDN en prod)."""
    return f"{settings.S3_PUBLIC_BASE_URL.rstrip('/')}/{key.lstrip('/')}"


def head(*, key: str, bucket: Bucket = "private") -> dict[str, object] | None:
    """Métadonnées d'un objet (taille, type), ou None s'il n'existe pas encore."""
    from botocore.exceptions import ClientError

    try:
        response = internal_client().head_object(Bucket=_bucket_name(bucket), Key=key)
    except ClientError as exc:
        if exc.response.get("Error", {}).get("Code") in {"404", "NoSuchKey", "NotFound"}:
            return None
        raise
    return {"size": response["ContentLength"], "content_type": response.get("ContentType")}


def read_head_bytes(*, key: str, length: int = 64, bucket: Bucket = "private") -> bytes:
    """Premiers octets d'un objet, pour vérifier le type réel (magic bytes)."""
    response = internal_client().get_object(Bucket=_bucket_name(bucket), Key=key, Range=f"bytes=0-{length - 1}")
    return response["Body"].read()


def delete(*, key: str, bucket: Bucket = "private") -> None:
    internal_client().delete_object(Bucket=_bucket_name(bucket), Key=key)
