"""
Événements de domaine : les applications communiquent sans s'importer mutuellement.

Un service publie (`publish(MealLogged(...))`) ; les abonnés sont déclarés dans `AppConfig.ready()`
avec `subscribe(MealLogged, handler)`. Les abonnés s'exécutent dans la transaction de l'émetteur :
une erreur annule l'écriture, ce qui garde les projections cohérentes.
"""

from __future__ import annotations

import uuid
from collections import defaultdict
from collections.abc import Callable
from dataclasses import dataclass
from datetime import date
from typing import Any, TypeVar

E = TypeVar("E", bound="DomainEvent")
Handler = Callable[[Any], None]

_handlers: dict[type[DomainEvent], list[Handler]] = defaultdict(list)


@dataclass(frozen=True, slots=True, kw_only=True)
class DomainEvent:
    user_id: uuid.UUID


@dataclass(frozen=True, slots=True, kw_only=True)
class UserRegistered(DomainEvent):
    invite_code: str | None
    device_fingerprint: str | None


@dataclass(frozen=True, slots=True, kw_only=True)
class EmailVerified(DomainEvent):
    pass


@dataclass(frozen=True, slots=True, kw_only=True)
class ProfileChanged(DomainEvent):
    fields: tuple[str, ...]


@dataclass(frozen=True, slots=True, kw_only=True)
class MealLogged(DomainEvent):
    meal_id: uuid.UUID
    day: date


@dataclass(frozen=True, slots=True, kw_only=True)
class DayRecomputed(DomainEvent):
    day: date


@dataclass(frozen=True, slots=True, kw_only=True)
class WaterLogged(DomainEvent):
    entry_id: uuid.UUID
    day: date


@dataclass(frozen=True, slots=True, kw_only=True)
class WeightLogged(DomainEvent):
    entry_id: uuid.UUID
    day: date


@dataclass(frozen=True, slots=True, kw_only=True)
class WorkoutCompleted(DomainEvent):
    session_id: uuid.UUID
    day: date


@dataclass(frozen=True, slots=True, kw_only=True)
class EntitlementChanged(DomainEvent):
    pass


@dataclass(frozen=True, slots=True, kw_only=True)
class AccountSuspended(DomainEvent):
    pass


def subscribe(event_type: type[E], handler: Callable[[E], None]) -> None:
    if handler not in _handlers[event_type]:
        _handlers[event_type].append(handler)


def publish(event: DomainEvent) -> None:
    for handler in list(_handlers[type(event)]):
        handler(event)
