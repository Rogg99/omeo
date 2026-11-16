import "server-only";

import { headers } from "next/headers";
import { forbidden, notFound, redirect } from "next/navigation";
import { cache } from "react";

import { createCan, type Can, type Permission } from "@/lib/permissions";
import source from "@/server/data/source";
import type { Problem, Result, StaffContext, StaffMember } from "@/server/data/types";

import { readSession } from "./session";

/**
 * Accès des Server Components : la personne connectée (GET /admin/me), mise en cache pour la durée
 * de la requête. L'interface filtre avec `can(permission)` ; l'API revérifie toujours.
 */

export type Staff = { me: StaffMember; ctx: StaffContext; can: Can };

async function currentPath(): Promise<string> {
  return (await headers()).get("x-pathname") ?? "/";
}

export const getStaff = cache(async (): Promise<Staff> => {
  const ctx = await readSession();
  const path = await currentPath();
  if (!ctx) redirect(`/session/refresh?next=${encodeURIComponent(path)}`);
  const result = await source.me.get(ctx);
  if (!result.ok) handleProblem(result.problem, path);
  const me = result.data;
  // Première connexion : la double authentification doit être enrôlée avant tout le reste.
  if (!me.mfa_enabled && path !== "/enroll") redirect("/enroll");
  return { me, ctx, can: createCan(me) };
});

/** Page réservée : sans la permission, écran « Accès refusé » (forbidden.tsx). */
export async function requirePermission(...permissions: Permission[]): Promise<Staff> {
  const staff = await getStaff();
  if (!permissions.some((p) => staff.can(p))) forbidden();
  return staff;
}

/**
 * Réaction commune aux erreurs de l'API pendant un rendu : session expirée → reconnexion,
 * 403 → écran dédié, 404 → page introuvable. Les autres erreurs remontent à error.tsx.
 */
export function handleProblem(problem: Problem, path = "/"): never {
  if (problem.status === 401) redirect(`/session/refresh?next=${encodeURIComponent(path)}`);
  if (problem.status === 403) forbidden();
  throw new ApiError(problem);
}

export class ApiError extends Error {
  constructor(readonly problem: Problem) {
    super(problem.code);
    this.name = "ApiError";
  }
}

/** Donnée d'un appel de lecture, ou réaction standard à l'erreur (voir handleProblem). */
export async function load<T>(result: Promise<Result<T>>): Promise<T> {
  const r = await result;
  if (r.ok) return r.data;
  if (r.problem.status === 404) notFound();
  return handleProblem(r.problem, await currentPath());
}
