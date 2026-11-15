"""
Délai croissant après des échecs de connexion répétés (conventions-api.md : « 5 par minute, puis délai croissant »).

Au-delà de `FREE_ATTEMPTS` échecs consécutifs pour un même compte, chaque nouvel essai est bloqué pendant
30 s, puis 60 s, 120 s… jusqu'à 15 minutes. Un succès remet le compteur à zéro. La clé est une empreinte de l'email :
aucune adresse n'est stockée en clair dans Redis.
"""

from __future__ import annotations

import hashlib
import time
from typing import Final

from django.core.cache import cache

from apps.core.errors import RateLimited

FREE_ATTEMPTS: Final = 5
BASE_DELAY_S: Final = 30
MAX_DELAY_S: Final = 15 * 60
WINDOW_S: Final = 24 * 3600


def _key(identifier: str) -> str:
    return "login-fail:" + hashlib.sha256(identifier.strip().lower().encode()).hexdigest()[:32]


def delay_for(failures: int) -> int:
    """Délai imposé après `failures` échecs (module pur)."""
    if failures < FREE_ATTEMPTS:
        return 0
    return min(BASE_DELAY_S * 2 ** (failures - FREE_ATTEMPTS), MAX_DELAY_S)


def check(identifier: str) -> None:
    state = cache.get(_key(identifier))
    if not state:
        return
    failures, last_failure = state
    remaining = int(last_failure + delay_for(failures) - time.time())
    if remaining > 0:
        raise RateLimited(headers={"Retry-After": str(remaining)}, meta={"retry_after": remaining})


def record_failure(identifier: str) -> None:
    key = _key(identifier)
    failures, _last = cache.get(key) or (0, 0.0)
    cache.set(key, (failures + 1, time.time()), WINDOW_S)


def reset(identifier: str) -> None:
    cache.delete(_key(identifier))
