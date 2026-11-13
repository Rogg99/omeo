"""
Fournisseurs du contrôle d'accès, enregistrés au démarrage par les applications qui les possèdent :
- `accounts` : permissions effectives d'un membre du staff et domaines de validation à quatre yeux ;
- `billing` : droits effectifs d'un utilisateur (Entitlement).

Le socle (`core`) ne dépend ainsi d'aucune application métier.
"""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any


@dataclass(slots=True)
class _Providers:
    permissions_for_user: Callable[[Any], frozenset[str]] | None = None
    can_decide_domain: Callable[[Any, str], bool] | None = None
    allows_feature: Callable[[Any, str], bool] | None = None


_providers = _Providers()


def register_permissions(
    *, permissions_for_user: Callable[[Any], frozenset[str]], can_decide_domain: Callable[[Any, str], bool]
) -> None:
    _providers.permissions_for_user = permissions_for_user
    _providers.can_decide_domain = can_decide_domain


def register_entitlements(*, allows_feature: Callable[[Any, str], bool]) -> None:
    _providers.allows_feature = allows_feature


def permissions_for_user(user: Any) -> frozenset[str]:
    if _providers.permissions_for_user is None:
        raise RuntimeError("accounts did not register its permission provider")
    return _providers.permissions_for_user(user)


def can_decide_domain(user: Any, domain: str) -> bool:
    if _providers.can_decide_domain is None:
        raise RuntimeError("accounts did not register its permission provider")
    return _providers.can_decide_domain(user, domain)


def allows_feature(user: Any, feature: str) -> bool:
    if _providers.allows_feature is None:
        raise RuntimeError("billing did not register its entitlement provider")
    return _providers.allows_feature(user, feature)
