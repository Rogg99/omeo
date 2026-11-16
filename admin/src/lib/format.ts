/**
 * Mise en forme pour l'affichage (Intl, langue de l'interface). Aucun calcul métier : les valeurs
 * viennent de l'API telles quelles (D1) ; on ne fait que les présenter.
 */
const LOCALE = "fr-FR";

export function formatNumber(value: number | null | undefined, digits = 0): string {
  if (value === null || value === undefined) return "—";
  return new Intl.NumberFormat(LOCALE, { maximumFractionDigits: digits }).format(value);
}

/** Ratio renvoyé par l'API (0,114) affiché en pourcentage (11,4 %). */
export function formatRatio(value: number | null | undefined, digits = 1): string {
  if (value === null || value === undefined) return "—";
  return new Intl.NumberFormat(LOCALE, { style: "percent", maximumFractionDigits: digits }).format(value);
}

export function formatDate(iso: string | null | undefined): string {
  if (!iso) return "—";
  return new Intl.DateTimeFormat(LOCALE, { day: "numeric", month: "short", year: "numeric" }).format(new Date(iso));
}

export function formatDateTime(iso: string | null | undefined): string {
  if (!iso) return "—";
  return new Intl.DateTimeFormat(LOCALE, { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }).format(
    new Date(iso),
  );
}

/** « il y a 4 min », « hier »… */
export function formatRelative(iso: string | null | undefined, now = Date.now()): string {
  if (!iso) return "—";
  const seconds = Math.round((Date.parse(iso) - now) / 1000);
  const rtf = new Intl.RelativeTimeFormat(LOCALE, { numeric: "auto" });
  const units: [Intl.RelativeTimeFormatUnit, number][] = [
    ["year", 31_536_000],
    ["month", 2_592_000],
    ["day", 86_400],
    ["hour", 3_600],
    ["minute", 60],
  ];
  for (const [unit, size] of units) if (Math.abs(seconds) >= size) return rtf.format(Math.round(seconds / size), unit);
  return rtf.format(seconds, "second");
}

/** Initiales d'un nom pour un avatar. */
export function initials(name: string | null | undefined): string {
  return (name ?? "?")
    .split(/[\s.@]+/)
    .filter(Boolean)
    .map((w) => w[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();
}
