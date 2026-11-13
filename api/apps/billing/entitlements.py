"""Matrice pure offre → fonctionnalités (docs/technique/controle-acces.md). Aucun accès à l'ORM."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Final

FEATURE_TIERS: Final[dict[str, frozenset[str]]] = {
    "text_analysis": frozenset({"trial", "plus"}),
    "progress_long_range": frozenset({"trial", "plus"}),
    "insights": frozenset({"trial", "plus"}),
    "programs": frozenset({"trial", "plus"}),
    "offline_workouts": frozenset({"plus"}),
    "full_catalog": frozenset({"trial", "plus"}),
    "weekly_report": frozenset({"trial", "plus"}),
    "streak_freeze": frozenset({"plus"}),
}

# Interrupteurs globaux de l'admin (`app.features`) qui coupent une fonctionnalité pour tout le monde.
GLOBAL_SWITCH: Final[dict[str, str]] = {
    "text_analysis": "text_analysis",
    "programs": "programs",
    "insights": "insights",
    "offline_workouts": "offline_workouts",
}


@dataclass(frozen=True, slots=True)
class Entitlement:
    tier: str
    trial_ends_at: datetime | None
    plus_until: datetime | None
    features: Mapping[str, bool] = field(default_factory=dict)

    def allows(self, feature: str) -> bool:
        return bool(self.features.get(feature, False))

    def as_dict(self) -> dict[str, Any]:
        return {
            "tier": self.tier,
            "trial_ends_at": self.trial_ends_at,
            "plus_until": self.plus_until,
            "features": dict(self.features),
        }


def resolve_tier(*, now: datetime, trial_ends_at: datetime | None, plus_until: datetime | None) -> str:
    if plus_until is not None and plus_until > now:
        return "plus"
    if trial_ends_at is not None and trial_ends_at > now:
        return "trial"
    return "free"


def features_for(tier: str, switches: Mapping[str, bool]) -> dict[str, bool]:
    out: dict[str, bool] = {}
    for feature, tiers in FEATURE_TIERS.items():
        switch = GLOBAL_SWITCH.get(feature)
        enabled = switches.get(switch, True) if switch else True
        out[feature] = tier in tiers and bool(enabled)
    return out


def build(
    *, now: datetime, trial_ends_at: datetime | None, plus_until: datetime | None, switches: Mapping[str, bool]
) -> Entitlement:
    tier = resolve_tier(now=now, trial_ends_at=trial_ends_at, plus_until=plus_until)
    return Entitlement(
        tier=tier,
        trial_ends_at=trial_ends_at,
        plus_until=plus_until if plus_until and plus_until > now else None,
        features=features_for(tier, switches),
    )
