import { cookies } from "next/headers";
import type { NextRequest } from "next/server";

import { DEFAULT_LOCALE, isLocale } from "@/i18n/routing";
import source from "@/server/data/source";
import { siteOrigin } from "@/server/env";
import { authorizeUrl, cookieOptions, newState, OAUTH_COOKIE, providerEnabled, serializeState } from "@/server/oauth";
import { safeNextPath } from "@/server/session-cookies";

/** Début de la connexion Google ou Apple : redirection vers le fournisseur (ou son simulateur). */
export async function GET(request: NextRequest, { params }: { params: Promise<{ provider: string }> }) {
  const { provider } = await params;
  const requested = request.nextUrl.searchParams.get("locale") ?? undefined;
  const locale = isLocale(requested) ? requested : DEFAULT_LOCALE;
  const login = new URL(`/${locale}/subscription/login`, siteOrigin);
  if (provider !== "google" && provider !== "apple") return Response.redirect(login, 303);

  if (source.demo) {
    return Response.redirect(new URL(`/${locale}/subscription/mock-social?provider=${provider}`, siteOrigin), 303);
  }
  if (!providerEnabled(provider)) {
    login.searchParams.set("error", "social_failed");
    return Response.redirect(login, 303);
  }

  const state = newState(provider, locale, safeNextPath(request.nextUrl.searchParams.get("next"), `/${locale}/subscription`));
  (await cookies()).set(OAUTH_COOKIE, serializeState(state), cookieOptions(provider));
  return Response.redirect(authorizeUrl(state), 303);
}
