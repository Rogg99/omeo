import type { Metadata } from "next";

import { DEFAULT_LOCALE, LOCALE_TAGS, LOCALES, type Locale } from "@/i18n/routing";

/** Adresse absolue d'une page dans une langue (`path` sans préfixe de langue, « / » pour l'accueil). */
export function localizedUrl(origin: string, locale: Locale, path: string): string {
  const suffix = path === "/" ? "" : path;
  return `${origin}/${locale}${suffix}`;
}

/** hreflang de toutes les langues, plus x-default (langue par défaut). */
export function languageAlternates(origin: string, path: string): Record<string, string> {
  const entries = LOCALES.map((l) => [LOCALE_TAGS[l], localizedUrl(origin, l, path)] as const);
  return { ...Object.fromEntries(entries), "x-default": localizedUrl(origin, DEFAULT_LOCALE, path) };
}

type PageMeta = {
  origin: string;
  locale: Locale;
  path: string;
  title: string;
  description: string;
  /** Titre complet, sans le gabarit « {page} · Omeo » (accueil). */
  absoluteTitle?: boolean;
  noindex?: boolean;
};

/** Métadonnées d'une page : canonique, hreflang, Open Graph et Twitter. */
export function pageMetadata({ origin, locale, path, title, description, absoluteTitle, noindex }: PageMeta): Metadata {
  const url = localizedUrl(origin, locale, path);
  return {
    title: absoluteTitle ? { absolute: title } : title,
    description,
    alternates: { canonical: url, languages: languageAlternates(origin, path) },
    openGraph: {
      type: "website",
      url,
      title,
      description,
      siteName: "Omeo",
      locale: LOCALE_TAGS[locale].replace("-", "_"),
      alternateLocale: LOCALES.filter((l) => l !== locale).map((l) => LOCALE_TAGS[l].replace("-", "_")),
    },
    twitter: { card: "summary_large_image", title, description },
    ...(noindex ? { robots: { index: false, follow: false } } : {}),
  };
}
