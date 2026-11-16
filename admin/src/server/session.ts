import "server-only";

import { cookies, headers } from "next/headers";

import source from "@/server/data/source";
import type { RequestContext, StaffContext, Tokens } from "@/server/data/types";

import { clientIpFrom } from "./request";
import {
  COOKIES,
  MAX_SESSION_MS,
  SESSION_COOKIE_NAMES,
  cookieOptions,
  decodeMeta,
  encodeMeta,
  isAccessFresh,
  sessionAge,
} from "./session-cookies";

/**
 * Session de l'équipe. Les jetons de l'API ne quittent jamais le serveur : cookies httpOnly,
 * SameSite=Strict, Secure et préfixés __Host- en HTTPS, renouvelés côté serveur.
 *
 * Les Server Components ne peuvent pas écrire de cookie : ils lisent (readSession). Le
 * renouvellement se fait dans src/proxy.ts (redirection vers /session/refresh), dans les Server
 * Actions et dans les route handlers (ensureSession).
 */

type CookieStore = Awaited<ReturnType<typeof cookies>>;

const REFRESH_MAX_AGE_S = Math.floor(MAX_SESSION_MS / 1000);

export async function requestContext(): Promise<RequestContext> {
  return { locale: "fr", clientIp: clientIpFrom(await headers()) };
}

/** Enregistre les jetons. `startedAt` conserve le début de session lors d'un renouvellement. */
export async function writeSession(store: CookieStore, tokens: Tokens, startedAt?: number): Promise<void> {
  const expiresAt = Date.parse(tokens.access_expires_at);
  const accessMaxAge = Math.max(60, Math.floor((expiresAt - Date.now()) / 1000));
  const now = Date.now();
  store.set(COOKIES.access, tokens.access, cookieOptions(accessMaxAge));
  store.set(COOKIES.expires, String(expiresAt), cookieOptions(accessMaxAge));
  store.set(COOKIES.refresh, tokens.refresh, cookieOptions(REFRESH_MAX_AGE_S));
  store.set(COOKIES.meta, await encodeMeta({ startedAt: startedAt ?? now, lastSeenAt: now }), cookieOptions(REFRESH_MAX_AGE_S));
}

export function clearSession(store: CookieStore): void {
  for (const name of SESSION_COOKIE_NAMES) store.delete({ name, path: "/" });
}

/** Début de session, si la session est encore dans ses durées d'inactivité et maximale. */
async function liveSessionStart(store: CookieStore): Promise<number | undefined> {
  const meta = await decodeMeta(store.get(COOKIES.meta)?.value);
  return meta && sessionAge(meta) === "active" ? meta.startedAt : undefined;
}

/** Jeton d'accès encore valable, sans renouvellement (Server Components). */
export async function readSession(): Promise<StaffContext | undefined> {
  const store = await cookies();
  const access = store.get(COOKIES.access)?.value;
  if (!access || !isAccessFresh(store.get(COOKIES.expires)?.value)) return undefined;
  if ((await liveSessionStart(store)) === undefined) return undefined;
  return { ...(await requestContext()), accessToken: access };
}

/**
 * Jeton d'accès valable, renouvelé si besoin (Server Actions et route handlers uniquement).
 * Un renouvellement refusé ou une session trop ancienne efface la session.
 */
export async function ensureSession(): Promise<StaffContext | undefined> {
  const current = await readSession();
  if (current) return current;
  const store = await cookies();
  const refresh = store.get(COOKIES.refresh)?.value;
  const startedAt = await liveSessionStart(store);
  if (!refresh || startedAt === undefined) {
    if (refresh) clearSession(store);
    return undefined;
  }
  const ctx = await requestContext();
  const result = await source.auth.refresh(refresh, ctx);
  if (!result.ok || !isAccessFresh(String(Date.parse(result.data.access_expires_at)))) {
    clearSession(store);
    return undefined;
  }
  await writeSession(store, result.data, startedAt);
  return { ...ctx, accessToken: result.data.access };
}
