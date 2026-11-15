import "server-only";

import { headers } from "next/headers";
import { getLocale } from "next-intl/server";

import { DEFAULT_LOCALE, isLocale, type Locale } from "@/i18n/routing";
import type { RequestContext } from "@/server/data/types";

/** Adresse IP du visiteur, posée par le proxy nginx (première adresse de X-Forwarded-For). */
export function clientIpFrom(h: Headers): string | undefined {
  const forwarded = h.get("x-forwarded-for")?.split(",")[0]?.trim();
  return forwarded || h.get("x-real-ip") || undefined;
}

export async function requestContext(locale?: Locale): Promise<RequestContext> {
  const h = await headers();
  const current = locale ?? (await getLocale());
  return { locale: isLocale(current) ? current : DEFAULT_LOCALE, clientIp: clientIpFrom(h) };
}

/** Clé de limitation de débit : l'adresse IP, ou un repli commun si elle est inconnue. */
export function rateKey(scope: string, ctx: { clientIp?: string }): string {
  return `${scope}:${ctx.clientIp ?? "unknown"}`;
}
