import type { Locale } from "@/i18n/routing";

import type { Money } from "../types";

/**
 * Montant en USD avec son libellé formaté selon la langue, comme le renvoie l'API.
 * Calcul toléré : il n'existe que dans le dossier mock, exclu des builds de production.
 */
export function usd(amountCents: number, locale: Locale): Money {
  const formatted = new Intl.NumberFormat(locale, { style: "currency", currency: "USD", currencyDisplay: "narrowSymbol" }).format(
    amountCents / 100,
  );
  return { amount_cents: amountCents, currency: "USD", formatted };
}
