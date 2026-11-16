import { NextResponse, type NextRequest } from "next/server";

import { adminOrigin, env } from "@/server/env-schema";
import {
  BACKGROUND_HEADER,
  COOKIES,
  SESSION_COOKIE_NAMES,
  cookieOptions,
  createCsrfToken,
  decodeMeta,
  encodeMeta,
  isAccessFresh,
  sessionAge,
} from "@/server/session-cookies";

/**
 * Proxy Next (s'exécute avant chaque requête) :
 * 1. CSRF : toute mutation doit venir de l'admin lui-même (en-tête Origin obligatoire) ;
 * 2. Session : redirection vers /login sans session, déconnexion après l'inactivité ou la durée
 *    maximale, renouvellement transparent du jeton d'accès avant le rendu ;
 * 3. Jeton CSRF (double soumission) posé dès la première visite ;
 * 4. CSP stricte avec un nonce par requête.
 */

const SAFE_METHODS = new Set(["GET", "HEAD", "OPTIONS"]);

/** Pages accessibles sans session. */
const PUBLIC = /^\/(login(\/.*)?|session\/.*|mock-upload\/.*)$/;
/** Routes techniques (JSON) : un refus renvoie un problème 401, jamais une redirection. */
const API = /^\/(api|mock-upload)\//;

export function contentSecurityPolicy(nonce: string, dev = env.NODE_ENV === "development"): string {
  const media = env.MEDIA_ORIGINS.join(" ");
  return [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${dev ? " 'unsafe-eval'" : ""}`,
    `style-src 'self' 'nonce-${nonce}'${dev ? " 'unsafe-inline'" : ""}`,
    // Positions calculées par Radix (popovers) et Recharts : attributs style uniquement.
    "style-src-attr 'unsafe-inline'",
    `img-src 'self' data: blob: ${media}`.trim(),
    `media-src 'self' blob: ${media}`.trim(),
    "font-src 'self'",
    `connect-src 'self' ${media}`.trim(),
    "frame-src 'none'",
    "worker-src 'self' blob:",
    "form-action 'self'",
    "frame-ancestors 'none'",
    "base-uri 'none'",
    "object-src 'none'",
    "manifest-src 'self'",
    ...(adminOrigin.startsWith("https://") ? ["upgrade-insecure-requests"] : []),
  ].join("; ");
}

/**
 * Une mutation n'est acceptée que si elle porte l'en-tête Origin de l'admin. Contrairement à la
 * vérification intégrée des Server Actions, une requête sans Origin est refusée.
 */
export function isSameOriginMutation(request: Pick<NextRequest, "method" | "headers">): boolean {
  if (SAFE_METHODS.has(request.method)) return true;
  return request.headers.get("origin") === adminOrigin;
}

function problem(status: number, code: string): NextResponse {
  return NextResponse.json(
    { type: "about:blank", title: code, status, code },
    { status, headers: { "content-type": "application/problem+json", "cache-control": "no-store" } },
  );
}

function clearSessionCookies(response: NextResponse): NextResponse {
  for (const name of SESSION_COOKIE_NAMES) response.cookies.delete({ name, path: "/" });
  return response;
}

function toLogin(request: NextRequest, reason?: "idle" | "expired"): NextResponse {
  const target = new URL("/login", adminOrigin);
  const next = `${request.nextUrl.pathname}${request.nextUrl.search}`;
  if (next !== "/") target.searchParams.set("next", next);
  if (reason) target.searchParams.set("reason", reason);
  return NextResponse.redirect(target, 303);
}

/** Navigation de la personne (et non prefetch ni interrogation périodique) : prolonge la session. */
function isActivity(request: NextRequest): boolean {
  const h = request.headers;
  return !h.has(BACKGROUND_HEADER) && !h.has("next-router-prefetch") && h.get("purpose") !== "prefetch";
}

export default async function proxy(request: NextRequest) {
  const { pathname, search } = request.nextUrl;
  const isApi = API.test(pathname);

  if (!isSameOriginMutation(request)) return problem(403, "forbidden");

  const { cookies } = request;
  const hasSession = cookies.has(COOKIES.access) || cookies.has(COOKIES.refresh);
  const meta = hasSession ? await decodeMeta(cookies.get(COOKIES.meta)?.value) : undefined;

  if (hasSession) {
    const age = meta ? sessionAge(meta) : "expired";
    if (age !== "active") {
      return clearSessionCookies(
        isApi ? problem(401, "not_authenticated") : toLogin(request, age === "idle" ? "idle" : "expired"),
      );
    }
  } else if (!PUBLIC.test(pathname)) {
    return isApi ? problem(401, "not_authenticated") : toLogin(request);
  }

  // Jeton d'accès expiré : renouvellement côté serveur avant le rendu de la page.
  const accessFresh = isAccessFresh(cookies.get(COOKIES.expires)?.value);
  if (hasSession && !accessFresh && request.method === "GET" && !isApi && !PUBLIC.test(pathname)) {
    const target = new URL("/session/refresh", adminOrigin);
    target.searchParams.set("next", `${pathname}${search}`);
    return NextResponse.redirect(target, 307);
  }

  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
  const csp = contentSecurityPolicy(nonce);

  // Jeton CSRF posé dès la première visite, et transmis au rendu de cette même requête.
  const csrf = cookies.get(COOKIES.csrf)?.value ?? (await createCsrfToken());
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
  requestHeaders.set("content-security-policy", csp);
  requestHeaders.set("x-pathname", pathname);
  if (!cookies.has(COOKIES.csrf)) {
    const existing = request.headers.get("cookie");
    requestHeaders.set("cookie", `${existing ? `${existing}; ` : ""}${COOKIES.csrf}=${csrf}`);
  }

  const response = NextResponse.next({ request: { headers: requestHeaders } });
  response.headers.set("Content-Security-Policy", csp);
  if (!cookies.has(COOKIES.csrf)) response.cookies.set(COOKIES.csrf, csrf, cookieOptions());
  if (meta && isActivity(request)) {
    response.cookies.set(
      COOKIES.meta,
      await encodeMeta({ startedAt: meta.startedAt, lastSeenAt: Date.now() }),
      cookieOptions(Math.floor(env.SESSION_MAX_HOURS * 3600)),
    );
  }
  return response;
}

export const config = {
  matcher: [
    {
      source: "/((?!_next/static|_next/image|demo/|favicon.ico|icon.svg|apple-icon.png|robots.txt).*)",
    },
  ],
};
