"""Types communs aux stores et à l'agrégateur de paiement web (interface `PaymentProvider`)."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Protocol


class ProviderError(RuntimeError):
    """Le fournisseur a refusé ou n'a pas répondu ; message destiné aux journaux, jamais à l'utilisateur."""


class InvalidSignatureError(ProviderError):
    pass


@dataclass(frozen=True, slots=True)
class VerifiedSubscription:
    """État d'un abonnement tel que confirmé par le store ou l'agrégateur (source de vérité)."""

    channel: str
    external_id: str
    product_id: str
    status: str  # active, grace, canceled, expired, refunded
    period_start: datetime
    period_end: datetime
    auto_renew: bool
    event_at: datetime
    raw: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class CheckoutSession:
    url: str
    expires_at: datetime


@dataclass(frozen=True, slots=True)
class ProviderEvent:
    """Événement normalisé de l'agrégateur web."""

    event_id: str
    type: str  # subscription_updated, payment_succeeded, payment_failed, refunded, ignored
    occurred_at: datetime
    user_id: str | None
    subscription: VerifiedSubscription | None = None
    payment: dict[str, Any] | None = None
    raw: dict[str, Any] = field(default_factory=dict)


class PaymentProvider(Protocol):
    """Agrégateur du paiement web. Implémentation par défaut : Stripe (question ouverte n°3)."""

    def create_checkout(
        self,
        *,
        user_id: str,
        email: str,
        price_id: str,
        amount_off_cents: int,
        percent_off: int,
        success_url: str,
        cancel_url: str,
        idempotency_key: str,
    ) -> CheckoutSession: ...

    def create_portal(self, *, customer_id: str, return_url: str) -> str: ...

    def refund(self, *, payment_external_id: str, amount_cents: int, idempotency_key: str) -> str: ...

    def parse_webhook(self, *, body: bytes, headers: dict[str, str]) -> ProviderEvent: ...
