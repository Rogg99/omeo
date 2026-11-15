import "server-only";

import { notFound } from "next/navigation";
import { connection } from "next/server";
import { setRequestLocale } from "next-intl/server";

import { isLocale, type Locale } from "./routing";

/**
 * Langue d'une page : 404 si elle n'existe pas, puis activée pour le rendu. La page attend la
 * requête (CSP à nonce) : aucun appel à l'API pendant le build ; les contenus de l'API restent
 * en cache 10 min ('use cache') et sont invalidés par le webhook.
 */
export async function pageLocale(params: Promise<{ locale: string }>): Promise<Locale> {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();
  setRequestLocale(locale);
  await connection();
  return locale;
}

/** Langue pour generateMetadata (sans effet de bord). */
export async function metadataLocale(params: Promise<{ locale: string }>): Promise<Locale | undefined> {
  const { locale } = await params;
  return isLocale(locale) ? locale : undefined;
}
