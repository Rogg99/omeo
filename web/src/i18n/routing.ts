import { defineRouting } from "next-intl/routing";

/** Langues du site (D19), une adresse par langue : /fr, /en… */
export const LOCALES = ["fr", "en", "es", "pt", "ar", "zh", "ja", "de"] as const;
export type Locale = (typeof LOCALES)[number];

export const DEFAULT_LOCALE: Locale = "fr";

/** Langues écrites de droite à gauche. */
const RTL: ReadonlySet<Locale> = new Set(["ar"]);

/** Nom de chaque langue dans sa propre langue (sélecteur de langue). */
export const LOCALE_NAMES: Record<Locale, string> = {
  fr: "Français",
  en: "English",
  es: "Español",
  pt: "Português",
  ar: "العربية",
  zh: "简体中文",
  ja: "日本語",
  de: "Deutsch",
};

/** Étiquette BCP 47 complète (hreflang, Open Graph). */
export const LOCALE_TAGS: Record<Locale, string> = {
  fr: "fr-FR",
  en: "en-US",
  es: "es-ES",
  pt: "pt-BR",
  ar: "ar",
  zh: "zh-CN",
  ja: "ja-JP",
  de: "de-DE",
};

export const LOCALE_COOKIE = "NEXT_LOCALE";

export function isLocale(value: string | undefined): value is Locale {
  return value !== undefined && (LOCALES as readonly string[]).includes(value);
}

export function direction(locale: Locale): "rtl" | "ltr" {
  return RTL.has(locale) ? "rtl" : "ltr";
}

export const routing = defineRouting({
  locales: LOCALES,
  defaultLocale: DEFAULT_LOCALE,
  localePrefix: "always",
  // Langue détectée par Accept-Language à la première visite, puis mémorisée
  localeDetection: true,
  localeCookie: { name: LOCALE_COOKIE, maxAge: 60 * 60 * 24 * 365, sameSite: "lax" },
  alternateLinks: false,
});
