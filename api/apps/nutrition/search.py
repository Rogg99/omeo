"""Normalisation des noms pour la recherche (minuscules, sans accents) : alimente `search_text` et les requêtes."""

from __future__ import annotations

import re
import unicodedata
from collections.abc import Iterable, Mapping
from typing import Final

_SPACES: Final = re.compile(r"\s+")


def normalize(text: str) -> str:
    decomposed = unicodedata.normalize("NFKD", text)
    stripped = "".join(ch for ch in decomposed if not unicodedata.combining(ch))
    return _SPACES.sub(" ", stripped.casefold()).strip()


def search_text(names: Mapping[str, str], aliases: Iterable[str]) -> str:
    """Tous les noms traduits et autres noms, normalisés, séparés par « | »."""
    values = [*names.values(), *aliases]
    return " | ".join(dict.fromkeys(normalize(v) for v in values if v))
