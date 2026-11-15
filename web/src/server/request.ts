import "server-only";

import { headers } from "next/headers";
import { getLocale } from "next-intl/server";

import { DEFAULT_LOCALE, isLocale, type Locale } from "@/i18n/routing";
import type { RequestContext } from "@/server/data/types";

/**
 * Adresse IP du visiteur. nginx pose X-Real-IP ($remote_addr) et ajoute le client à la fin de
 * X-Forwarded-For : les premières adresses de cette chaîne viennent du client et peuvent être
 * falsifiées, elles ne servent jamais à la limitation de débit.
 */
export function clientIpFrom(h: Headers): string | undefined {
  const real = h.get("x-real-ip")?.trim();
  if (real) return real;
  const last = h.get("x-forwarded-for")?.split(",").at(-1)?.trim();
  return last || undefined;
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
