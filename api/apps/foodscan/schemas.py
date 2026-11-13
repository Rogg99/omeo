"""
Formats échangés par le moteur de scan (module pur, sans Django).

- `ScanOutput` : la réponse de l'IA, validée strictement. Tout ce qui sort du
  cadre fait échouer l'analyse en `provider_error` plutôt que d'être deviné.
- `DishHint` / `ConfusionHint` : ce que la base des avis validés injecte dans
  le prompt.

L'IA ne renvoie AUCUN nutriment : les valeurs viennent toujours de la base
d'aliments (`nutrition.Food`), après rapprochement des ingrédients.
"""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

MAX_LABEL_LENGTH = 80


def normalize_key(value: str | None) -> str:
    """Clé stable d'un plat : « Ndolé aux crevettes » -> « ndole_aux_crevettes »."""
    if not value:
        return ""
    text = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii").lower()
    text = re.sub(r"[^a-z0-9]+", "_", text).strip("_")
    return text[:MAX_LABEL_LENGTH]


def clean_label(value: str | None) -> str:
    """Libellé sûr à réinjecter dans un prompt : une ligne, sans balisage, longueur bornée."""
    if not value:
        return ""
    text = re.sub(r"[\x00-\x1f\x7f`{}<>\[\]]", " ", value)
    text = re.sub(r"\s+", " ", text).strip()
    return text[:MAX_LABEL_LENGTH]


class _Strict(BaseModel):
    model_config = ConfigDict(extra="ignore", str_strip_whitespace=True)


class ScanItem(_Strict):
    label: str = Field(min_length=1, max_length=MAX_LABEL_LENGTH)
    grams: float = Field(gt=0, le=3000)
    confidence: float = Field(default=0.5, ge=0, le=1)


class ScanAlternative(_Strict):
    dish_label: str = Field(min_length=1, max_length=MAX_LABEL_LENGTH)
    dish_key: str | None = None
    confidence: float = Field(default=0.0, ge=0, le=1)


class ScanOutput(_Strict):
    contains_food: bool
    image_quality: Literal["ok", "blurry"] = "ok"
    dish_label: str | None = Field(default=None, max_length=MAX_LABEL_LENGTH)
    # Clé d'une fiche connue quand le plat en fait partie, sinon null.
    dish_key: str | None = Field(default=None, max_length=MAX_LABEL_LENGTH)
    confidence: float = Field(default=0.0, ge=0, le=1)
    alternatives: list[ScanAlternative] = Field(default_factory=list, max_length=3)
    items: list[ScanItem] = Field(default_factory=list, max_length=20)
    # Une règle de confusion apprise a-t-elle fait changer d'avis ? (traçabilité)
    applied_rules: list[str] = Field(default_factory=list, max_length=20)

    @field_validator("dish_key")
    @classmethod
    def _normalize_dish_key(cls, value: str | None) -> str | None:
        return normalize_key(value) or None

    @field_validator("alternatives")
    @classmethod
    def _normalize_alternatives(cls, value: list[ScanAlternative]) -> list[ScanAlternative]:
        for alt in value:
            alt.dish_key = normalize_key(alt.dish_key) or None
        return value


@dataclass(frozen=True, slots=True)
class DishHint:
    """Fiche d'un plat local, rédigée ou validée par l'équipe."""

    key: str
    name: str
    visual_description: str
    distinguishing_tips: str = ""
    aliases: tuple[str, ...] = ()
    scope: Literal["country", "region"] = "country"


@dataclass(frozen=True, slots=True)
class ConfusionHint:
    """Erreur déjà corrigée par plusieurs utilisateurs, puis validée."""

    predicted_key: str
    predicted_label: str
    correct_key: str
    correct_label: str
    support: int
    hint: str = ""
