import "server-only";

import { createHash, randomBytes } from "node:crypto";

import type { Locale } from "@/i18n/routing";
import type { SocialProvider } from "@/server/data/types";
import { appleSignInEnabled, env, googleSignInEnabled, isSecureSite, siteOrigin } from "@/server/env";

/**
 * Connexion Google et Apple côté serveur (flux « authorization code »), sans script tiers :
 * le site redirige vers le fournisseur, reçoit le jeton d'identité et le transmet à l'API
 * (/auth/social), qui le vérifie. État, nonce et vérificateur PKCE vivent dans un cookie httpOnly.
 */
export const OAUTH_COOKIE = "omeo_oauth";
export const OAUTH_TTL_S = 600;

export type OAuthState = { provider: SocialProvider; state: string; nonce: string; verifier: string; locale: Locale; next: string };

const random = () => randomBytes(32).toString("base64url");

export function providerEnabled(provider: SocialProvider): boolean {
  return provider === "google" ? googleSignInEnabled : appleSignInEnabled;
}

export function callbackUrl(provider: SocialProvider): string {
  return `${siteOrigin}/auth/${provider}/callback`;
}

export function newState(provider: SocialProvider, locale: Locale, next: string): OAuthState {
  return { provider, state: random(), nonce: random(), verifier: random(), locale, next };
}

/** Le retour Apple est un POST cross-site (form_post) : son cookie doit être SameSite=None, donc Secure. */
export function cookieOptions(provider: SocialProvider) {
  const crossSite = provider === "apple" && isSecureSite;
  return { httpOnly: true, secure: isSecureSite, sameSite: crossSite ? ("none" as const) : ("lax" as const), path: "/auth", maxAge: OAUTH_TTL_S };
}

export function authorizeUrl(s: OAuthState): string {
  if (s.provider === "google") {
    const url = new URL("https://accounts.google.com/o/oauth2/v2/auth");
    url.search = new URLSearchParams({
      client_id: env.GOOGLE_CLIENT_ID ?? "",
      redirect_uri: callbackUrl("google"),
      response_type: "code",
      scope: "openid email",
      state: s.state,
      nonce: s.nonce,
      code_challenge: createHash("sha256").update(s.verifier).digest("base64url"),
      code_challenge_method: "S256",
      prompt: "select_account",
    }).toString();
    return url.toString();
  }
  const url = new URL("https://appleid.apple.com/auth/authorize");
  url.search = new URLSearchParams({
    client_id: env.APPLE_SERVICE_ID ?? "",
    redirect_uri: callbackUrl("apple"),
    response_type: "code id_token",
    response_mode: "form_post",
    scope: "email",
    state: s.state,
    nonce: s.nonce,
  }).toString();
  return url.toString();
}

/** Échange du code Google contre le jeton d'identité (secret client côté serveur uniquement). */
export async function googleIdToken(code: string, verifier: string): Promise<string | undefined> {
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      code,
      client_id: env.GOOGLE_CLIENT_ID ?? "",
      client_secret: env.GOOGLE_CLIENT_SECRET ?? "",
      redirect_uri: callbackUrl("google"),
      grant_type: "authorization_code",
      code_verifier: verifier,
    }),
    signal: AbortSignal.timeout(10_000),
  }).catch(() => undefined);
  if (!response?.ok) return undefined;
  const body = (await response.json().catch(() => ({}))) as { id_token?: unknown };
  return typeof body.id_token === "string" ? body.id_token : undefined;
}

export function parseState(raw: string | undefined): OAuthState | undefined {
  if (!raw) return undefined;
  try {
    const value = JSON.parse(Buffer.from(raw, "base64url").toString("utf8")) as OAuthState;
    return typeof value.state === "string" && typeof value.nonce === "string" ? value : undefined;
  } catch {
    return undefined;
  }
}

export function serializeState(s: OAuthState): string {
  return Buffer.from(JSON.stringify(s)).toString("base64url");
}
