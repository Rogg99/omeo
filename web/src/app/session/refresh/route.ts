import type { NextRequest } from "next/server";

import { DEFAULT_LOCALE, isLocale } from "@/i18n/routing";
import { siteOrigin } from "@/server/env";
import { clientIpFrom } from "@/server/request";
import { ensureSession } from "@/server/session";
import { safeNextPath } from "@/server/session-cookies";

/**
 * Renouvelle la session avant le rendu d'une page Abonnement (un composant serveur ne peut pas
 * écrire de cookie), puis renvoie vers la page demandée. Appelé par src/proxy.ts.
 */
export async function GET(request: NextRequest) {
  const requested = request.nextUrl.searchParams.get("next");
  const segment = requested?.split("/")[1];
  const locale = isLocale(segment) ? segment : DEFAULT_LOCALE;
  const next = safeNextPath(requested, `/${locale}/subscription`);
  const session = await ensureSession({ locale, clientIp: clientIpFrom(request.headers) });
  const target = session ? next : `/${locale}/subscription/login?expired=1`;
  return Response.redirect(new URL(target, siteOrigin), 303);
}
