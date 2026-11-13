"""
Préparation d'une photo avant l'envoi à l'IA (module pur, sans Django).

- Redressement EXIF : les téléphones rangent la rotation dans les
  métadonnées ; sans redressement la photo arrive couchée (constaté dans
  foodscanner).
- Ré-encodage JPEG sans métadonnées : la position GPS ne quitte jamais l'API.
- Réduction à MAX_SIDE px : au-delà, l'IA ne voit pas mieux mais coûte plus.
"""

from __future__ import annotations

import base64
import io

from PIL import Image, ImageOps, UnidentifiedImageError

MAX_SIDE = 1280
JPEG_QUALITY = 85
MAX_INPUT_BYTES = 8 * 1024 * 1024
# Garde-fou contre les « bombes de décompression ».
MAX_PIXELS = 40_000_000


class UnsupportedImageError(ValueError):
    """Fichier illisible, trop lourd ou qui n'est pas une image."""


def prepare_image(data: bytes) -> bytes:
    """Renvoie un JPEG redressé, réduit et sans métadonnées."""
    if not data:
        raise UnsupportedImageError("Fichier vide.")
    if len(data) > MAX_INPUT_BYTES:
        raise UnsupportedImageError("Fichier trop lourd (8 Mo maximum).")
    try:
        with Image.open(io.BytesIO(data)) as source:
            if source.width * source.height > MAX_PIXELS:
                raise UnsupportedImageError("Image trop grande.")
            image = ImageOps.exif_transpose(source).convert("RGB")
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as exc:
        raise UnsupportedImageError("Format d'image non reconnu ou fichier corrompu.") from exc

    image.thumbnail((MAX_SIDE, MAX_SIDE), Image.Resampling.LANCZOS)
    output = io.BytesIO()
    # Pas d'exif= : le JPEG produit ne porte aucune métadonnée.
    image.save(output, format="JPEG", quality=JPEG_QUALITY, optimize=True)
    return output.getvalue()


def to_data_url(jpeg: bytes) -> str:
    return "data:image/jpeg;base64," + base64.b64encode(jpeg).decode("ascii")
