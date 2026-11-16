/**
 * Proxy des vues très interactives (TanStack Query : filtres en direct, interrogation périodique)
 * vers l'API Omeo. Le navigateur ne connaît ni l'adresse de l'API ni les jetons :
 * - liste blanche : /admin/* et /auth/mfa/step-up (connexion et jetons passent par les Server Actions) ;
 * - jeton d'accès lu dans le cookie httpOnly, renouvelé au besoin côté serveur ;
 * - mutations : en-tête Origin (proxy) ET jeton CSRF à double soumission ;
 * - en-têtes sensibles retirés dans les deux sens, X-Forwarded-For transmis.
 *
 * En mode mock, aucune requête HTTP ne part : seules les lectures prises en charge par la couche de
 * données sont servies (voir MOCK_ROUTES).
 */
import type { NextRequest } from "next/server";

import source from "@/server/data/source";
import { env } from "@/server/env";
import { clientIpFrom } from "@/server/request";
import { ensureSession } from "@/server/session";
import { COOKIES, CSRF_HEADER, isValidCsrf } from "@/server/session-cookies";

/** Liste blanche : /admin/* et, côté /auth/*, la seule revalidation du second facteur. */
const ALLOWED = /^(admin(\/[\w.-]+)+|auth\/mfa\/step-up)$/;
const SAFE_METHODS = new Set(["GET", "HEAD"]);
/** En-têtes de requête transmis à l'API ; tout le reste (cookies, Authorization du client…) est retiré. */
const FORWARDED_REQUEST_HEADERS = ["accept", "accept-language", "content-type", "idempotency-key", "if-match"];
/** En-têtes de réponse renvoyés au navigateur. */
const FORWARDED_RESPONSE_HEADERS = ["content-type", "etag", "retry-after", "x-request-id"];
const TIMEOUT_MS = 15_000;

function problem(status: number, code: string): Response {
  return Response.json(
    { type: "about:blank", title: code, status, code },
    { status, headers: { "content-type": "application/problem+json", "cache-control": "no-store" } },
  );
}

type Params = { params: Promise<{ path: string[] }> };

/** Lectures servies en mode mock (mêmes réponses que l'API, par la couche de données). */
const MOCK_ROUTES: Record<string, (ctx: Parameters<typeof source.me.get>[0], search: URLSearchParams) => Promise<unknown>> = {
  "admin/me": (ctx) => source.me.get(ctx),
};

async function handle(request: NextRequest, { params }: Params): Promise<Response> {
  const { path } = await params;
  const joined = path.join("/");
  if (!ALLOWED.test(joined) || path.some((p) => p === ".." || p === ".")) return problem(404, "not_found");

  if (!SAFE_METHODS.has(request.method)) {
    const valid = await isValidCsrf(request.cookies.get(COOKIES.csrf)?.value, request.headers.get(CSRF_HEADER));
    if (!valid) return problem(403, "csrf_failed");
  }

  const ctx = await ensureSession();
  if (!ctx) return problem(401, "not_authenticated");

  if (source.demo) {
    const route = request.method === "GET" ? MOCK_ROUTES[joined] : undefined;
    if (!route) return problem(404, "not_found");
    const result = (await route(ctx, request.nextUrl.searchParams)) as { ok: boolean; data?: unknown; problem?: { status: number } };
    return result.ok
      ? Response.json(result.data, { headers: { "cache-control": "private, no-store" } })
      : Response.json(result.problem, { status: result.problem?.status ?? 500, headers: { "content-type": "application/problem+json" } });
  }

  const headers = new Headers();
  for (const name of FORWARDED_REQUEST_HEADERS) {
    const value = request.headers.get(name);
    if (value) headers.set(name, value);
  }
  headers.set("authorization", `Bearer ${ctx.accessToken}`);
  const ip = clientIpFrom(request.headers);
  if (ip) headers.set("x-forwarded-for", ip);

  const target = `${env.API_URL_INTERNAL}${env.API_BASE_PATH}/${joined}${request.nextUrl.search}`;
  let upstream: Response;
  try {
    upstream = await fetch(target, {
      method: request.method,
      headers,
      body: SAFE_METHODS.has(request.method) ? undefined : await request.arrayBuffer(),
      redirect: "manual",
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
  } catch {
    return problem(503, "network_error");
  }

  const responseHeaders = new Headers({ "cache-control": "private, no-store" });
  for (const name of FORWARDED_RESPONSE_HEADERS) {
    const value = upstream.headers.get(name);
    if (value) responseHeaders.set(name, value);
  }
  return new Response(upstream.body, { status: upstream.status, headers: responseHeaders });
}

export { handle as GET, handle as POST, handle as PUT, handle as PATCH, handle as DELETE };
