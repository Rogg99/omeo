import "server-only";

import { notFound } from "next/navigation";
import { setRequestLocale } from "next-intl/server";

import { isLocale, type Locale } from "./routing";

/** Langue d'une page : 404 si elle n'existe pas, puis activée pour le rendu. */
export async function pageLocale(params: Promise<{ locale: string }>): Promise<Locale> {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();
  setRequestLocale(locale);
  return locale;
}

/** Langue pour generateMetadata (sans effet de bord). */
export async function metadataLocale(params: Promise<{ locale: string }>): Promise<Locale | undefined> {
  const { locale } = await params;
  return isLocale(locale) ? locale : undefined;
}
