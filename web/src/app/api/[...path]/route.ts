/**
 * Proxy des îlots client vers l'API Omeo.
 *
 * Le navigateur n'appelle jamais l'API : il appelle /api/... sur ce domaine. Seule une liste
 * blanche d'endpoints est servie, chacun par la couche de données (même code en mock et en réel) :
 * l'adresse de l'API et les jetons restent sur le serveur, le jeton d'accès est lu dans le cookie
 * httpOnly et renouvelé au besoin. Limitation de débit par adresse IP.
 */
import type { NextRequest } from "next/server";
import { z } from "zod";

import { DEFAULT_LOCALE, isLocale } from "@/i18n/routing";
import source from "@/server/data/source";
import type { AuthedContext, Problem, RequestContext, Result } from "@/server/data/types";
import { hit, RATE_LIMITS } from "@/server/rate-limit";
import { clientIpFrom, rateKey } from "@/server/request";
import { ensureSession } from "@/server/session";

type Handler = (request: NextRequest, ctx: RequestContext) => Promise<Response>;

const PROBLEM_TYPE = "application/problem+json";

function problem(status: number, code: string, extra?: Partial<Problem>): Response {
  const body: Problem = { type: "about:blank", title: code, status, code, ...extra };
  return Response.json(body, { status, headers: { "content-type": PROBLEM_TYPE, "cache-control": "no-store" } });
}

function reply<T>(result: Result<T>): Response {
  if (!result.ok) {
    return Response.json(result.problem, {
      status: result.problem.status,
      headers: { "content-type": PROBLEM_TYPE, "cache-control": "no-store" },
    });
  }
  return Response.json(result.data, { headers: { "cache-control": "private, no-store" } });
}

async function body<T>(request: NextRequest, schema: z.ZodType<T>): Promise<T | undefined> {
  try {
    const parsed = schema.safeParse(await request.json());
    return parsed.success ? parsed.data : undefined;
  } catch {
    return undefined;
  }
}

function authed(run: (request: NextRequest, ctx: AuthedContext) => Promise<Response>): Handler {
  return async (request, ctx) => {
    const session = await ensureSession(ctx);
    return session ? run(request, session) : problem(401, "not_authenticated");
  };
}

const promoInput = z.object({ code: z.string().trim().min(1).max(40), plan_code: z.enum(["plus_monthly", "plus_annual"]) });

/** Liste blanche : « MÉTHODE chemin » → traitement. */
const ROUTES: Record<string, Handler> = {
  "GET me/subscription": authed(async (_request, ctx) => reply(await source.billing.subscription(ctx))),
  "GET me/payments": authed(async (request, ctx) =>
    reply(await source.billing.payments(request.nextUrl.searchParams.get("cursor") ?? undefined, ctx)),
  ),
  "POST me/billing/promo-check": authed(async (request, ctx) => {
    const input = await body(request, promoInput);
    return input ? reply(await source.billing.promoCheck(input, ctx)) : problem(400, "validation_error");
  }),
};

function localeOf(request: NextRequest) {
  const header = request.headers.get("accept-language")?.split(",")[0]?.split("-")[0];
  const cookie = request.cookies.get("NEXT_LOCALE")?.value;
  return isLocale(cookie) ? cookie : isLocale(header) ? header : DEFAULT_LOCALE;
}

async function handle(request: NextRequest, { params }: { params: Promise<{ path: string[] }> }) {
  const { path } = await params;
  const route = ROUTES[`${request.method} ${path.join("/")}`];
  if (!route) return problem(404, "not_found");

  const ctx: RequestContext = { locale: localeOf(request), clientIp: clientIpFrom(request.headers) };
  const limit = hit(rateKey("api", ctx), RATE_LIMITS.api);
  if (!limit.ok) {
    const response = problem(429, "rate_limited");
    response.headers.set("retry-after", String(limit.retryAfterSeconds));
    return response;
  }
  return route(request, ctx);
}

export { handle as GET, handle as POST };
