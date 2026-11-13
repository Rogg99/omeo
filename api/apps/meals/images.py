"""
Nettoyage des images téléversées (module pur, sans ORM).

1. Type réel vérifié par les magic bytes (le Content-Type déclaré n'est pas une preuve).
2. HEIC/HEIF converti en JPEG (pillow-heif).
3. Redressement EXIF puis ré-encodage SANS métadonnées : la position GPS ne quitte jamais l'API.
"""

from __future__ import annotations

import io
from dataclasses import dataclass
from typing import Final

from PIL import Image, ImageOps, UnidentifiedImageError
from pillow_heif import register_heif_opener

register_heif_opener()

MAX_BYTES: Final = 8 * 1024 * 1024
MAX_PIXELS: Final = 40_000_000
JPEG_QUALITY: Final = 88


class InvalidImageError(ValueError):
    def __init__(self, reason: str) -> None:
        super().__init__(reason)
        self.reason = reason


@dataclass(frozen=True, slots=True)
class CleanImage:
    data: bytes
    content_type: str
    width: int
    height: int


def sniff(data: bytes) -> str | None:
    """Type MIME réel d'après la signature du fichier."""
    if data.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    if data[4:8] == b"ftyp" and data[8:12] in {b"heic", b"heix", b"hevc", b"hevx", b"mif1", b"msf1", b"heim", b"heis"}:
        return "image/heic"
    return None


def sanitize(data: bytes) -> CleanImage:
    if not data:
        raise InvalidImageError("empty")
    if len(data) > MAX_BYTES:
        raise InvalidImageError("too_large")
    real_type = sniff(data)
    if real_type is None:
        raise InvalidImageError("unsupported_type")
    try:
        with Image.open(io.BytesIO(data)) as source:
            if source.width * source.height > MAX_PIXELS:
                raise InvalidImageError("too_many_pixels")
            image = ImageOps.exif_transpose(source)
            image.load()
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError):
        raise InvalidImageError("corrupted") from None

    output = io.BytesIO()
    if real_type == "image/png":
        image.save(output, format="PNG", optimize=True)
        content_type = "image/png"
    elif real_type == "image/webp":
        image.save(output, format="WEBP", quality=JPEG_QUALITY)
        content_type = "image/webp"
    else:  # JPEG et HEIC → JPEG
        image.convert("RGB").save(output, format="JPEG", quality=JPEG_QUALITY, optimize=True)
        content_type = "image/jpeg"
    return CleanImage(data=output.getvalue(), content_type=content_type, width=image.width, height=image.height)
