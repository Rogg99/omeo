import type { NextRequest } from "next/server";

import { DEFAULT_LOCALE, isLocale } from "@/i18n/routing";
import { siteOrigin } from "@/server/env";
import { normalizeInviteCode, platformOf, storeUrlFor } from "@/server/stores";

/**
 * Cible du QR code : renvoie vers Google Play ou l'App Store selon le téléphone, en conservant le
 * code d'invitation éventuel. Sur ordinateur, renvoie vers la section Télécharger de l'accueil.
 */
export function GET(request: NextRequest) {
  const code = normalizeInviteCode(request.nextUrl.searchParams.get("code"));
  const store = storeUrlFor(platformOf(request.headers.get("user-agent")), code);
  if (store) return Response.redirect(store, 302);
  const cookie = request.cookies.get("NEXT_LOCALE")?.value;
  const locale = isLocale(cookie) ? cookie : DEFAULT_LOCALE;
  return Response.redirect(new URL(`/${locale}#download`, siteOrigin), 302);
}
