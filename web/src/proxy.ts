import { NextResponse, type NextRequest } from "next/server";
import createIntlMiddleware from "next-intl/middleware";

import { isLocale, routing } from "@/i18n/routing";
import { env, isSecureSite, siteOrigin } from "@/server/env-schema";
import { isAccessFresh, SESSION_COOKIES } from "@/server/session-cookies";

/**
 * Proxy Next (s'exécute avant chaque requête) :
 * 1. CSRF : toute mutation doit venir du site lui-même (en-tête Origin) ;
 * 2. Abonnement : renouvelle la session avant le rendu si le jeton d'accès a expiré ;
 * 3. Langue : préfixe /fr, /en… (Accept-Language à la première visite, puis cookie) ;
 * 4. CSP stricte avec un nonce par requête.
 */

const intl = createIntlMiddleware(routing);

const SAFE_METHODS = new Set(["GET", "HEAD", "OPTIONS"]);

/** Routes techniques, hors langue. */
const TECHNICAL = /^\/(api|session|hooks|download|stats|auth)(\/|$)|^\/(sitemap\.xml|robots\.txt)$/;

/**
 * Mutations venues d'ailleurs par conception : le webhook de revalidation (signé HMAC) et le retour
 * de Sign in with Apple (form_post depuis appleid.apple.com, protégé par l'état signé).
 */
const ORIGIN_EXEMPT = /^\/(hooks\/revalidate|auth\/apple\/callback)$/;

const TURNSTILE = "https://challenges.cloudflare.com";

export function contentSecurityPolicy(nonce: string, dev = env.NODE_ENV === "development"): string {
  const formTargets = ["'self'", ...env.PAYMENT_ORIGINS, "https://accounts.google.com", "https://appleid.apple.com"];
  return [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic' ${TURNSTILE}${dev ? " 'unsafe-eval'" : ""}`,
    `style-src 'self' 'nonce-${nonce}'${dev ? " 'unsafe-inline'" : ""}`,
    "style-src-attr 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self'",
    `connect-src 'self' ${TURNSTILE}`,
    `frame-src ${TURNSTILE}`,
    `form-action ${formTargets.join(" ")}`,
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "object-src 'none'",
    "manifest-src 'self'",
    ...(isSecureSite ? ["upgrade-insecure-requests"] : []),
  ].join("; ");
}

/** Une mutation est acceptée si elle vient du site (Origin, ou Sec-Fetch-Site à défaut). */
export function isSameOriginMutation(request: Pick<NextRequest, "method" | "headers">): boolean {
  if (SAFE_METHODS.has(request.method)) return true;
  const origin = request.headers.get("origin");
  if (origin) return origin === siteOrigin;
  return request.headers.get("sec-fetch-site") === "same-origin";
}

function forbidden(): Response {
  return Response.json(
    { type: "about:blank", title: "Forbidden", status: 403, code: "forbidden" },
    { status: 403, headers: { "content-type": "application/problem+json" } },
  );
}

/**
 * Transmet des en-têtes de requête supplémentaires au rendu, en conservant ceux qu'a déjà posés
 * next-intl (même mécanisme que NextResponse.next({ request: { headers } })).
 */
function forwardRequestHeaders(response: NextResponse, request: NextRequest, extra: Record<string, string>): void {
  const merged = new Headers(request.headers);
  const overridden = response.headers.get("x-middleware-override-headers");
  for (const key of overridden?.split(",") ?? []) {
    const value = response.headers.get(`x-middleware-request-${key}`);
    if (value !== null) merged.set(key, value);
  }
  for (const [key, value] of Object.entries(extra)) merged.set(key, value);
  response.headers.set("x-middleware-override-headers", [...merged.keys()].join(","));
  for (const [key, value] of merged) response.headers.set(`x-middleware-request-${key}`, value);
}

function needsRefresh(request: NextRequest): boolean {
  const [, locale, section, step] = request.nextUrl.pathname.split("/");
  if (!isLocale(locale) || section !== "subscription" || step === "login" || step?.startsWith("mock-")) return false;
  const { cookies } = request;
  return !isAccessFresh(cookies.get(SESSION_COOKIES.expires)?.value) && cookies.has(SESSION_COOKIES.refresh);
}

export default function proxy(request: NextRequest) {
  const { pathname, search } = request.nextUrl;

  if (!ORIGIN_EXEMPT.test(pathname) && !isSameOriginMutation(request)) return forbidden();
  if (TECHNICAL.test(pathname)) return NextResponse.next();

  if (request.method === "GET" && needsRefresh(request)) {
    const target = new URL("/session/refresh", siteOrigin);
    target.searchParams.set("next", `${pathname}${search}`);
    return NextResponse.redirect(target, 307);
  }

  const response = intl(request);
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
  const csp = contentSecurityPolicy(nonce);
  forwardRequestHeaders(response, request, { "x-nonce": nonce, "content-security-policy": csp, "x-pathname": pathname });
  response.headers.set("Content-Security-Policy", csp);
  return response;
}

export const config = {
  matcher: [
    {
      source: "/((?!_next/static|_next/image|images/|fonts/|favicon.ico|icon.svg|apple-icon.png).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
    },
  ],
};
