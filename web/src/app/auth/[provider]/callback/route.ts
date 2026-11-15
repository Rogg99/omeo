import { timingSafeEqual } from "node:crypto";

import { cookies } from "next/headers";
import type { NextRequest } from "next/server";

import { DEFAULT_LOCALE } from "@/i18n/routing";
import source from "@/server/data/source";
import { siteOrigin } from "@/server/env";
import { googleIdToken, OAUTH_COOKIE, parseState, type OAuthState } from "@/server/oauth";
import { clientIpFrom } from "@/server/request";
import { finishSocial } from "@/server/subscription";

function sameState(a: string, b: string): boolean {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}

/** Termine la connexion : état vérifié, jeton d'identité transmis à l'API, cookies de session posés. */
async function complete(request: NextRequest, provider: string, params: URLSearchParams) {
  const store = await cookies();
  const saved: OAuthState | undefined = parseState(store.get(OAUTH_COOKIE)?.value);
  store.delete({ name: OAUTH_COOKIE, path: "/auth" });

  const locale = saved?.locale ?? DEFAULT_LOCALE;
  const fail = (error: string) => Response.redirect(new URL(`/${locale}/subscription/login?error=${error}`, siteOrigin), 303);

  const state = params.get("state");
  if (!saved || saved.provider !== provider || !state || !sameState(state, saved.state)) return fail("social_failed");

  let idToken: string | undefined;
  if (provider === "google") {
    const code = params.get("code");
    idToken = code ? await googleIdToken(code, saved.verifier) : undefined;
  } else {
    idToken = params.get("id_token") ?? undefined;
  }
  if (!idToken) return fail("social_failed");

  const ctx = { locale, clientIp: clientIpFrom(request.headers) };
  const outcome = await finishSocial(await source.auth.social(saved.provider, idToken, saved.nonce, ctx), ctx);
  return outcome === "ok" ? Response.redirect(new URL(saved.next, siteOrigin), 303) : fail(outcome);
}

/** Google : retour en GET. */
export async function GET(request: NextRequest, { params }: { params: Promise<{ provider: string }> }) {
  const { provider } = await params;
  if (provider !== "google") return new Response(null, { status: 405 });
  return complete(request, provider, request.nextUrl.searchParams);
}

/** Apple : retour en POST (form_post), exempté du contrôle d'Origin, protégé par l'état. */
export async function POST(request: NextRequest, { params }: { params: Promise<{ provider: string }> }) {
  const { provider } = await params;
  if (provider !== "apple") return new Response(null, { status: 405 });
  const form = await request.formData().catch(() => undefined);
  const values = new URLSearchParams();
  for (const [key, value] of form ?? []) if (typeof value === "string") values.set(key, value);
  return complete(request, provider, values);
}
