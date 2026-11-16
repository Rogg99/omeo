import type { components } from "@/lib/api/schema";

/** Langues des contenus (contrat : Locale). Le français est la langue de référence. */
export type Locale = components["schemas"]["Locale"];

export const LOCALES = ["fr", "en", "es", "pt", "ar", "zh", "ja", "de"] as const satisfies readonly Locale[];

export const REFERENCE_LOCALE: Locale = "fr";

/** Langues qui s'écrivent de droite à gauche. */
const RTL: ReadonlySet<Locale> = new Set(["ar"]);

export function direction(locale: Locale): "rtl" | "ltr" {
  return RTL.has(locale) ? "rtl" : "ltr";
}

export function isLocale(value: unknown): value is Locale {
  return typeof value === "string" && (LOCALES as readonly string[]).includes(value);
}
