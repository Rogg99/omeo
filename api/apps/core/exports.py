"""
Sections de l'export RGPD. Chaque application enregistre, dans son `AppConfig.ready()`, une fonction qui renvoie
ses propres données pour un utilisateur ; `support` assemble l'archive sans lire les tables des autres.
"""

from __future__ import annotations

from collections.abc import Callable
from typing import Any

Section = Callable[[Any], list[dict[str, Any]]]
_sections: dict[str, Section] = {}


def register_section(name: str, section: Section) -> None:
    _sections[name] = section


def collect(user: Any) -> dict[str, list[dict[str, Any]]]:
    return {name: section(user) for name, section in sorted(_sections.items())}
