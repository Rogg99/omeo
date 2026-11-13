"""
Règles du moteur de validation des avis (module pur, sans Django).

Un avis isolé ne change jamais le comportement de l'IA : un utilisateur qui se
trompe, ou qui veut nuire, polluerait les analyses de tout son pays. Une
correction ne devient une règle que si :
- un validateur de confiance (équipe, nutritionniste) l'approuve ; ou
- assez d'utilisateurs DISTINCTS proposent la même correction dans le même
  pays, et elle l'emporte nettement sur les avis contraires.
"""

from __future__ import annotations

from collections import defaultdict
from collections.abc import Iterable
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Vote:
    """Une correction proposée : « l'IA a dit `predicted_key`, c'était `correct_key` »."""

    user_id: str
    country: str
    predicted_key: str
    correct_key: str
    predicted_label: str = ""
    correct_label: str = ""


@dataclass(frozen=True, slots=True)
class ConsensusPolicy:
    min_distinct_users: int = 3
    # Part minimale des votes de la paire parmi toutes les corrections du même
    # (pays, plat prédit) : évite d'apprendre une règle sur un plat dont les
    # utilisateurs ne s'accordent pas.
    min_agreement: float = 0.6


@dataclass(frozen=True, slots=True)
class RuleCandidate:
    country: str
    predicted_key: str
    correct_key: str
    predicted_label: str
    correct_label: str
    support: int
    agreement: float
    accepted: bool


def is_correction(predicted_key: str, correct_key: str) -> bool:
    """Un avis qui confirme le plat (👍) n'est pas une correction."""
    return bool(predicted_key and correct_key and predicted_key != correct_key)


def evaluate(votes: Iterable[Vote], policy: ConsensusPolicy) -> list[RuleCandidate]:
    """
    Regroupe les corrections par (pays, plat prédit, plat correct) et dit
    lesquelles atteignent le consensus. Chaque utilisateur compte une seule fois
    par paire, quel que soit son nombre d'avis.
    """
    users_by_pair: dict[tuple[str, str, str], set[str]] = defaultdict(set)
    users_by_predicted: dict[tuple[str, str], set[tuple[str, str]]] = defaultdict(set)
    labels: dict[tuple[str, str, str], tuple[str, str]] = {}

    for vote in votes:
        if not is_correction(vote.predicted_key, vote.correct_key):
            continue
        pair = (vote.country, vote.predicted_key, vote.correct_key)
        users_by_pair[pair].add(vote.user_id)
        users_by_predicted[(vote.country, vote.predicted_key)].add((vote.user_id, vote.correct_key))
        labels.setdefault(pair, (vote.predicted_label or vote.predicted_key, vote.correct_label or vote.correct_key))

    candidates = []
    for pair, users in users_by_pair.items():
        country, predicted, correct = pair
        total = len(users_by_predicted[(country, predicted)])
        support = len(users)
        agreement = support / total if total else 0.0
        candidates.append(
            RuleCandidate(
                country=country,
                predicted_key=predicted,
                correct_key=correct,
                predicted_label=labels[pair][0],
                correct_label=labels[pair][1],
                support=support,
                agreement=round(agreement, 3),
                accepted=support >= policy.min_distinct_users and agreement >= policy.min_agreement,
            )
        )
    return sorted(candidates, key=lambda c: (-c.support, c.country, c.predicted_key, c.correct_key))
