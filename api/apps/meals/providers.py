"""
Compositions de recettes fournies par `content` (enregistrées dans son `AppConfig.ready()`), pour les repas
`source = recipe | program`. `meals` n'importe jamais les modèles de `content`.
"""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from decimal import Decimal
from typing import Any


@dataclass(frozen=True, slots=True)
class RecipeComposition:
    recipe_id: Any
    title: str
    items: list[tuple[Any, Decimal]]  # (Food, grammes) pour UNE portion


RecipeResolver = Callable[[Any, Any], RecipeComposition | None]
_resolvers: list[RecipeResolver] = []


def register_recipe_resolver(resolver: RecipeResolver) -> None:
    _resolvers[:] = [resolver]


def resolve_recipe(*, user: Any, recipe_id: Any) -> RecipeComposition | None:
    """Recette publiée et accessible à l'utilisateur (droits vérifiés par `content`), sinon None."""
    return _resolvers[0](user, recipe_id) if _resolvers else None
