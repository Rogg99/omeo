import "server-only";

import createClient from "openapi-fetch";

import { env } from "@/server/env";

import type { Applied, ApprovalRequest, Page, Problem, RequestContext, Result, StaffContext, paths } from "./types";

/**
 * Client typé de l'API Omeo, généré depuis contracts/openapi.yaml (`pnpm gen:api`).
 * Uniquement côté serveur, sur le réseau interne (API_URL_INTERNAL) : l'adresse de l'API et les
 * jetons ne sont jamais visibles du navigateur.
 */
export const api = createClient<paths>({
  baseUrl: `${env.API_URL_INTERNAL ?? ""}${env.API_BASE_PATH}`,
  headers: { Accept: "application/json" },
});

/** Délai maximal d'un appel à l'API. */
const TIMEOUT_MS = 15_000;

export function headers(ctx: RequestContext, extra?: Record<string, string>): Record<string, string> {
  return {
    "Accept-Language": ctx.locale,
    ...(ctx.clientIp ? { "X-Forwarded-For": ctx.clientIp } : {}),
    ...extra,
  };
}

/** En-têtes et délai d'un appel authentifié. */
export function authed(ctx: StaffContext) {
  return { headers: headers(ctx, { Authorization: `Bearer ${ctx.accessToken}` }), signal: AbortSignal.timeout(TIMEOUT_MS) };
}

/** En-têtes et délai d'un appel anonyme (connexion, second facteur, renouvellement). */
export function anonymous(ctx: RequestContext) {
  return { headers: headers(ctx), signal: AbortSignal.timeout(TIMEOUT_MS) };
}

export function isProblem(value: unknown): value is Problem {
  return typeof value === "object" && value !== null && "code" in value && "status" in value;
}

export function problem(status: number, code: string): Problem {
  return { type: "about:blank", title: code, status, code };
}

type Outcome<T> = { data?: T; error?: unknown; response: Response };

async function run<T>(request: () => Promise<Outcome<T>>): Promise<Outcome<T> | Problem> {
  try {
    return await request();
  } catch {
    return problem(503, "network_error");
  }
}

function failure(outcome: Outcome<unknown>): Problem {
  return isProblem(outcome.error) ? outcome.error : problem(outcome.response.status, "server_error");
}

/** Réponse sans corps attendu (204). */
export async function callEmpty<T>(request: () => Promise<Outcome<T>>): Promise<Result<null>> {
  const outcome = await run(request);
  if (isProblem(outcome)) return { ok: false, problem: outcome };
  return outcome.response.ok ? { ok: true, data: null } : { ok: false, problem: failure(outcome) };
}

/** Réponse avec corps. Une erreur réseau ou non conforme devient `network_error` ou `server_error`. */
export async function call<T>(request: () => Promise<Outcome<T>>): Promise<Result<NonNullable<T>>> {
  const outcome = await run(request);
  if (isProblem(outcome)) return { ok: false, problem: outcome };
  if (!outcome.response.ok) return { ok: false, problem: failure(outcome) };
  if (outcome.data === undefined || outcome.data === null) return { ok: false, problem: problem(502, "server_error") };
  return { ok: true, data: outcome.data };
}

type PageBody<T> = { results?: T[]; count: number; page: number; page_size: number };

/** Liste paginée (PageMeta & { results }) : `results` est toujours présent dans la Page renvoyée. */
export async function paged<T>(request: () => Promise<Outcome<PageBody<T>>>): Promise<Result<Page<T>>> {
  const result = await call(request);
  if (!result.ok) return result;
  const { results, count, page, page_size } = result.data;
  return { ok: true, data: { results: results ?? [], count, page, page_size } };
}

/**
 * Action « quatre yeux » : 202 + ApprovalRequest (validation par une autre personne) ou 200 avec la
 * ressource à jour. Le statut HTTP fait foi, jamais la forme du corps.
 */
export async function callApplied<T>(request: () => Promise<Outcome<unknown>>): Promise<Result<Applied<T>>> {
  const outcome = await run(request);
  if (isProblem(outcome)) return { ok: false, problem: outcome };
  if (!outcome.response.ok) return { ok: false, problem: failure(outcome) };
  if (outcome.data === undefined || outcome.data === null) return { ok: false, problem: problem(502, "server_error") };
  if (outcome.response.status === 202) {
    return { ok: true, data: { status: "pending", approval: outcome.data as ApprovalRequest } };
  }
  return { ok: true, data: { status: "applied", data: outcome.data as T } };
}
