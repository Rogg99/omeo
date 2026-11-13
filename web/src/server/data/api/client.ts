import "server-only";

import createClient from "openapi-fetch";

import type { paths } from "@/lib/api/schema";
import { env } from "@/server/env";

import type { AuthedContext, Problem, RequestContext, Result } from "../types";

/**
 * Client typé de l'API Omeo, généré depuis contracts/openapi.yaml (`pnpm gen:api`).
 * Appels uniquement côté serveur, sur le réseau interne (API_URL_INTERNAL) : l'adresse de l'API
 * et les jetons ne sont jamais visibles du navigateur.
 */
export const api = createClient<paths>({
  baseUrl: `${env.API_URL_INTERNAL ?? ""}/api/v1`,
  headers: { Accept: "application/json" },
});

/** Délai maximal d'un appel à l'API. */
const TIMEOUT_MS = 10_000;

export function headers(ctx: RequestContext, extra?: Record<string, string>): Record<string, string> {
  return {
    "Accept-Language": ctx.locale,
    ...(ctx.clientIp ? { "X-Forwarded-For": ctx.clientIp } : {}),
    ...extra,
  };
}

export function authHeaders(ctx: AuthedContext, extra?: Record<string, string>): Record<string, string> {
  return headers(ctx, { Authorization: `Bearer ${ctx.accessToken}`, ...extra });
}

export const requestInit = () => ({ signal: AbortSignal.timeout(TIMEOUT_MS) });

function isProblem(value: unknown): value is Problem {
  return typeof value === "object" && value !== null && "code" in value && "status" in value;
}

function fallbackProblem(status: number, code: string): Problem {
  return { type: "about:blank", title: code, status, code };
}

type Outcome<T> = { data?: T; error?: unknown; response: Response };

/**
 * Convertit une réponse openapi-fetch en Result. Une erreur réseau ou une réponse d'erreur qui
 * n'est pas du problem+json devient un problème `network_error` ou `server_error`.
 */
export async function call<T>(request: () => Promise<Outcome<T>>): Promise<Result<NonNullable<T> | null>> {
  let outcome: Outcome<T>;
  try {
    outcome = await request();
  } catch {
    return { ok: false, problem: fallbackProblem(503, "network_error") };
  }
  if (outcome.response.ok) return { ok: true, data: outcome.data ?? null };
  if (isProblem(outcome.error)) return { ok: false, problem: outcome.error };
  return { ok: false, problem: fallbackProblem(outcome.response.status, "server_error") };
}

/** Variante pour les réponses qui ont toujours un corps. */
export async function callWithBody<T>(request: () => Promise<Outcome<T>>): Promise<Result<NonNullable<T>>> {
  const result = await call(request);
  if (!result.ok) return result;
  if (result.data === null) return { ok: false, problem: fallbackProblem(502, "server_error") };
  return { ok: true, data: result.data };
}

/**
 * Erreur levée dans une fonction mise en cache (`use cache`) : une erreur n'est jamais mise en
 * cache, elle est reconvertie en Result par `settle`.
 */
export class ProblemError extends Error {
  constructor(readonly problem: Problem) {
    super(problem.code);
  }
}

export async function orThrow<T>(result: Promise<Result<T>>): Promise<T> {
  const r = await result;
  if (!r.ok) throw new ProblemError(r.problem);
  return r.data;
}

export async function settle<T>(promise: Promise<T>): Promise<Result<T>> {
  try {
    return { ok: true, data: await promise };
  } catch (error) {
    if (error instanceof ProblemError) return { ok: false, problem: error.problem };
    throw error;
  }
}
