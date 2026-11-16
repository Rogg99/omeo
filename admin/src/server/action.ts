import "server-only";

import { refresh } from "next/cache";
import { cookies } from "next/headers";
import type { z } from "zod";

import type { ActionProblem, ActionResult } from "@/lib/action-result";
import type { Applied, Problem, Result, StaffContext } from "@/server/data/types";

import { ensureSession } from "./session";
import { COOKIES, isValidCsrf } from "./session-cookies";

/**
 * Socle des Server Actions de l'admin. Chaque action est un point d'entrée public : on revérifie
 * tout, dans cet ordre :
 * 1. jeton CSRF (double soumission signée), en plus du contrôle d'Origin du proxy et de Next ;
 * 2. session valable (renouvelée au besoin) ;
 * 3. validation zod de l'entrée ;
 * 4. appel de la couche de données : l'API applique permissions, step-up et quatre yeux.
 */

type Input = { csrf?: unknown };

export function toActionProblem(problem: Problem): ActionProblem {
  const errors = problem.errors
    ? Object.fromEntries(Object.entries(problem.errors).map(([k, list]) => [k, list.map((e) => e.message)]))
    : undefined;
  return {
    status: problem.status,
    code: problem.code,
    ...(problem.detail ? { detail: problem.detail } : {}),
    ...(errors ? { errors } : {}),
    ...(problem.meta ? { meta: problem.meta } : {}),
  };
}

const fail = (status: number, code: string, errors?: Record<string, string[]>): { ok: false; problem: ActionProblem } => ({
  ok: false,
  problem: { status, code, ...(errors ? { errors } : {}) },
});

function zodErrors(error: z.ZodError): Record<string, string[]> {
  const out: Record<string, string[]> = {};
  for (const issue of error.issues) {
    const key = issue.path.join(".") || "_";
    (out[key] ??= []).push(issue.message);
  }
  return out;
}

type Options = { refreshPage?: boolean };

/** Contrôles communs : CSRF, session, validation. */
async function prepare<S extends z.ZodType>(
  raw: unknown,
  schema: S,
): Promise<{ ok: true; input: z.infer<S>; ctx: StaffContext } | { ok: false; problem: ActionProblem }> {
  const input = (typeof raw === "object" && raw !== null ? raw : {}) as Input;
  const store = await cookies();
  if (!(await isValidCsrf(store.get(COOKIES.csrf)?.value, typeof input.csrf === "string" ? input.csrf : null))) {
    return fail(403, "csrf_failed");
  }
  const ctx = await ensureSession();
  if (!ctx) return fail(401, "not_authenticated");
  const { csrf: _csrf, ...rest } = input;
  const parsed = schema.safeParse(rest);
  if (!parsed.success) return fail(422, "validation_error", zodErrors(parsed.error));
  return { ok: true, input: parsed.data, ctx };
}

/** Action authentifiée. Une réussite rafraîchit la page courante, sauf `refreshPage: false`. */
export async function staffAction<S extends z.ZodType, T>(
  raw: unknown,
  schema: S,
  handler: (input: z.infer<S>, ctx: StaffContext) => Promise<Result<T>>,
  options: Options = {},
): Promise<ActionResult<T>> {
  const prepared = await prepare(raw, schema);
  if (!prepared.ok) return prepared;
  const result = await handler(prepared.input, prepared.ctx);
  if (!result.ok) return { ok: false, problem: toActionProblem(result.problem) };
  if (options.refreshPage !== false) refresh();
  return { ok: true, data: result.data };
}

/**
 * Action « quatre yeux » : appliquée (200) ou transformée en demande de validation par une autre
 * personne (202), renvoyée au client comme `pending`.
 */
export async function staffAppliedAction<S extends z.ZodType, T>(
  raw: unknown,
  schema: S,
  handler: (input: z.infer<S>, ctx: StaffContext) => Promise<Result<Applied<T>>>,
  options: Options = {},
): Promise<ActionResult<T>> {
  const prepared = await prepare(raw, schema);
  if (!prepared.ok) return prepared;
  const result = await handler(prepared.input, prepared.ctx);
  if (!result.ok) return { ok: false, problem: toActionProblem(result.problem) };
  if (options.refreshPage !== false) refresh();
  const applied = result.data;
  return applied.status === "pending" ? { ok: true, pending: applied.approval } : { ok: true, data: applied.data };
}

/** Action anonyme (connexion) : CSRF et validation, sans session. */
export async function publicAction<S extends z.ZodType>(
  raw: unknown,
  schema: S,
): Promise<{ ok: true; data: z.infer<S> } | { ok: false; problem: ActionProblem }> {
  const input = (typeof raw === "object" && raw !== null ? raw : {}) as Input;
  const store = await cookies();
  if (!(await isValidCsrf(store.get(COOKIES.csrf)?.value, typeof input.csrf === "string" ? input.csrf : null))) {
    return fail(403, "csrf_failed");
  }
  const { csrf: _csrf, ...rest } = input;
  const parsed = schema.safeParse(rest);
  return parsed.success ? { ok: true, data: parsed.data } : fail(422, "validation_error", zodErrors(parsed.error));
}
