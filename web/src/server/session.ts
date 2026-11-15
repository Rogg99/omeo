import "server-only";

import { cookies } from "next/headers";

import source from "@/server/data/source";
import type { AuthedContext, RequestContext, Tokens } from "@/server/data/types";
import { isSecureSite } from "@/server/env";

import { isAccessFresh, SESSION_COOKIES } from "./session-cookies";

/**
 * Session de la page Abonnement. Les jetons de l'API ne quittent jamais le serveur : ils vivent dans
 * des cookies httpOnly, Secure (en HTTPS) et SameSite=Lax, et sont renouvelés côté serveur.
 *
 * Les composants serveur ne peuvent pas écrire de cookie : ils lisent seulement (readSession).
 * Le renouvellement se fait dans src/proxy.ts (redirection vers /session/refresh), dans les
 * Server Actions et dans les route handlers (ensureSession).
 */
const REFRESH_MAX_AGE_S = 30 * 24 * 60 * 60;

type CookieStore = Awaited<ReturnType<typeof cookies>>;

const base = () => ({ httpOnly: true, secure: isSecureSite, sameSite: "lax" as const, path: "/" });

export function writeSession(store: CookieStore, tokens: Tokens, email?: string): void {
  const expiresAt = Date.parse(tokens.access_expires_at);
  const accessMaxAge = Math.max(60, Math.floor((expiresAt - Date.now()) / 1000));
  store.set(SESSION_COOKIES.access, tokens.access, { ...base(), maxAge: accessMaxAge });
  store.set(SESSION_COOKIES.expires, String(expiresAt), { ...base(), maxAge: accessMaxAge });
  store.set(SESSION_COOKIES.refresh, tokens.refresh, { ...base(), maxAge: REFRESH_MAX_AGE_S });
  if (email) store.set(SESSION_COOKIES.email, email, { ...base(), maxAge: REFRESH_MAX_AGE_S });
}

/** Email du compte connecté, s'il est connu. */
export async function sessionEmail(): Promise<string | undefined> {
  return (await cookies()).get(SESSION_COOKIES.email)?.value;
}

export function clearSession(store: CookieStore): void {
  for (const name of Object.values(SESSION_COOKIES)) store.delete({ name, path: "/" });
}

/** Jeton d'accès encore valable, sans renouvellement (composants serveur). */
export async function readSession(ctx: RequestContext): Promise<AuthedContext | undefined> {
  const store = await cookies();
  const access = store.get(SESSION_COOKIES.access)?.value;
  if (!access || !isAccessFresh(store.get(SESSION_COOKIES.expires)?.value)) return undefined;
  return { ...ctx, accessToken: access };
}

/**
 * Jeton d'accès valable, renouvelé si besoin (Server Actions et route handlers uniquement).
 * Un renouvellement refusé efface la session.
 */
export async function ensureSession(ctx: RequestContext): Promise<AuthedContext | undefined> {
  const current = await readSession(ctx);
  if (current) return current;
  const store = await cookies();
  const refresh = store.get(SESSION_COOKIES.refresh)?.value;
  if (!refresh) return undefined;
  const result = await source.auth.refresh(refresh, ctx);
  // Jeton renouvelé déjà expiré (horloge décalée, réponse figée) : échec, sinon boucle de redirections.
  if (!result.ok || !isAccessFresh(String(Date.parse(result.data.access_expires_at)))) {
    clearSession(store);
    return undefined;
  }
  writeSession(store, result.data);
  return { ...ctx, accessToken: result.data.access };
}
