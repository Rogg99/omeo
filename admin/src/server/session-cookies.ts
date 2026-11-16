/**
 * Cookies de session de l'admin et leurs signatures. Sans marqueur server-only : utilisé aussi par
 * src/proxy.ts. Uniquement du Web Crypto (HMAC SHA-256), disponible partout.
 *
 * - Jetons de l'API : httpOnly, Secure en HTTPS, SameSite=Strict, préfixe __Host- en HTTPS.
 * - `meta` : début de session et dernière activité, signés. Déconnexion après SESSION_IDLE_MINUTES
 *   d'inactivité et au bout de SESSION_MAX_HOURS au plus, vérifiées par le proxy ET par le serveur.
 * - `csrf` : jeton aléatoire signé (double soumission). Le serveur le transmet à la page, qui le
 *   renvoie dans l'en-tête X-CSRF-Token ou dans le champ `csrf` des Server Actions.
 */
import { env, isSecureAdmin, sessionSecret } from "./env-schema";

const prefix = isSecureAdmin ? "__Host-" : "";

export const COOKIES = {
  access: `${prefix}omeo_admin_at`,
  refresh: `${prefix}omeo_admin_rt`,
  /** Échéance du jeton d'accès (ms epoch), pour décider d'un renouvellement sans décoder le jeton. */
  expires: `${prefix}omeo_admin_exp`,
  meta: `${prefix}omeo_admin_meta`,
  csrf: `${prefix}omeo_admin_csrf`,
  /** Jeton du second facteur entre les deux étapes de la connexion (5 min). */
  mfa: `${prefix}omeo_admin_mfa`,
} as const;

/** Cookies effacés à la déconnexion (le jeton CSRF reste : il protège aussi la page de connexion). */
export const SESSION_COOKIE_NAMES = [COOKIES.access, COOKIES.refresh, COOKIES.expires, COOKIES.meta, COOKIES.mfa] as const;

export const CSRF_HEADER = "x-csrf-token";
/** En-tête des appels d'arrière-plan (interrogation périodique) : ne prolongent pas la session. */
export const BACKGROUND_HEADER = "x-omeo-background";

export const IDLE_MS = env.SESSION_IDLE_MINUTES * 60 * 1000;
export const MAX_SESSION_MS = env.SESSION_MAX_HOURS * 60 * 60 * 1000;
/** Marge avant échéance : un jeton qui expire dans moins de 30 s est considéré comme expiré. */
export const EXPIRY_MARGIN_MS = 30_000;

export function cookieOptions(maxAgeSeconds?: number) {
  return {
    httpOnly: true,
    secure: isSecureAdmin,
    sameSite: "strict" as const,
    path: "/",
    ...(maxAgeSeconds !== undefined ? { maxAge: maxAgeSeconds } : {}),
  };
}

const encoder = new TextEncoder();
let keyPromise: Promise<CryptoKey> | undefined;

function key(): Promise<CryptoKey> {
  keyPromise ??= crypto.subtle.importKey("raw", encoder.encode(sessionSecret), { name: "HMAC", hash: "SHA-256" }, false, [
    "sign",
    "verify",
  ]);
  return keyPromise;
}

function toBase64Url(bytes: ArrayBuffer | Uint8Array): string {
  const array = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  let binary = "";
  for (const b of array) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function fromBase64Url(value: string): Uint8Array<ArrayBuffer> | undefined {
  try {
    const binary = atob(value.replace(/-/g, "+").replace(/_/g, "/"));
    const bytes = new Uint8Array(new ArrayBuffer(binary.length));
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    return bytes;
  } catch {
    return undefined;
  }
}

async function sign(purpose: string, payload: string): Promise<string> {
  return toBase64Url(await crypto.subtle.sign("HMAC", await key(), encoder.encode(`${purpose}:${payload}`)));
}

/** Vérification à temps constant (crypto.subtle.verify). */
async function verify(purpose: string, payload: string, signature: string): Promise<boolean> {
  const bytes = fromBase64Url(signature);
  if (!bytes) return false;
  return crypto.subtle.verify("HMAC", await key(), bytes, encoder.encode(`${purpose}:${payload}`));
}

// ── Durée de session ─────────────────────────────────────────────────────────

export type SessionMeta = { startedAt: number; lastSeenAt: number };

export async function encodeMeta(meta: SessionMeta): Promise<string> {
  const payload = `${meta.startedAt}.${meta.lastSeenAt}`;
  return `${payload}.${await sign("meta", payload)}`;
}

export async function decodeMeta(value: string | undefined): Promise<SessionMeta | undefined> {
  if (!value) return undefined;
  const [started, seen, signature] = value.split(".");
  if (!started || !seen || !signature || !(await verify("meta", `${started}.${seen}`, signature))) return undefined;
  const startedAt = Number(started);
  const lastSeenAt = Number(seen);
  return Number.isFinite(startedAt) && Number.isFinite(lastSeenAt) ? { startedAt, lastSeenAt } : undefined;
}

export type SessionAge = "active" | "idle" | "expired";

/** État d'une session au regard des durées d'inactivité et maximale. */
export function sessionAge(meta: SessionMeta, now = Date.now()): SessionAge {
  if (now - meta.startedAt >= MAX_SESSION_MS) return "expired";
  if (now - meta.lastSeenAt >= IDLE_MS) return "idle";
  return "active";
}

export function isAccessFresh(expires: string | undefined, now = Date.now()): boolean {
  const at = Number(expires);
  return expires !== undefined && Number.isFinite(at) && at - EXPIRY_MARGIN_MS > now;
}

// ── CSRF (double soumission signée) ──────────────────────────────────────────

export async function createCsrfToken(): Promise<string> {
  const nonce = toBase64Url(crypto.getRandomValues(new Uint8Array(24)));
  return `${nonce}.${await sign("csrf", nonce)}`;
}

/** Le jeton reçu doit être identique au cookie ET signé par le serveur. */
export async function isValidCsrf(cookie: string | undefined, submitted: string | null | undefined): Promise<boolean> {
  if (!cookie || !submitted || cookie.length !== submitted.length) return false;
  let diff = 0;
  for (let i = 0; i < cookie.length; i++) diff |= cookie.charCodeAt(i) ^ submitted.charCodeAt(i);
  if (diff !== 0) return false;
  const [nonce, signature] = cookie.split(".");
  return Boolean(nonce && signature && (await verify("csrf", nonce, signature)));
}

/** Une destination de redirection n'est acceptée que si elle reste dans l'admin. */
export function safeNextPath(next: string | null | undefined, fallback = "/"): string {
  if (!next || !next.startsWith("/") || next.startsWith("//") || next.includes("\\") || next.startsWith("/login")) {
    return fallback;
  }
  return next;
}
