"""Calculs de prix purs (aucun ORM) : remises des codes promo, équivalent mensuel, économie, formatage USD."""

from __future__ import annotations

from dataclasses import dataclass
from decimal import ROUND_HALF_UP, Decimal
from typing import Final

MONTHS_PER_YEAR: Final = 12
# Formatage par langue : séparateur décimal et position du symbole.
_FORMATS: Final[dict[str, tuple[str, bool]]] = {
    "fr": (",", False),
    "es": (",", False),
    "pt": (",", False),
    "de": (",", False),
    "ar": (".", False),
    "en": (".", True),
    "zh": (".", True),
    "ja": (".", True),
}


@dataclass(frozen=True, slots=True)
class Discount:
    kind: str  # percent, amount, free_days
    value: int


def apply_discount(price_cents: int, discount: Discount) -> int:
    """Prix remisé en cents, jamais négatif. `free_days` ne change pas le prix (jours offerts en plus)."""
    if discount.kind == "percent":
        reduced = Decimal(price_cents) * (Decimal(100) - Decimal(min(discount.value, 100))) / Decimal(100)
        return max(int(reduced.quantize(Decimal(1), rounding=ROUND_HALF_UP)), 0)
    if discount.kind == "amount":
        return max(price_cents - discount.value, 0)
    return price_cents


def monthly_equivalent(price_cents: int, interval: str) -> int | None:
    if interval != "year":
        return None
    return int((Decimal(price_cents) / MONTHS_PER_YEAR).quantize(Decimal(1), rounding=ROUND_HALF_UP))


def savings_percent(*, annual_cents: int, monthly_cents: int) -> int | None:
    full_year = monthly_cents * MONTHS_PER_YEAR
    if full_year <= 0 or annual_cents >= full_year:
        return None
    ratio = (Decimal(full_year - annual_cents) / Decimal(full_year)) * 100
    return int(ratio.quantize(Decimal(1), rounding=ROUND_HALF_UP))


def format_usd(amount_cents: int, locale: str) -> str:
    separator, symbol_first = _FORMATS.get(locale, (".", True))
    units, cents = divmod(abs(amount_cents), 100)
    number = f"{units}{separator}{cents:02d}"
    sign = "-" if amount_cents < 0 else ""
    return f"{sign}${number}" if symbol_first else f"{sign}{number} $"


def money(amount_cents: int, locale: str) -> dict[str, object]:
    """Montant au format du contrat (`Money`), formaté pour la langue demandée."""
    return {"amount_cents": amount_cents, "currency": "USD", "formatted": format_usd(amount_cents, locale)}
