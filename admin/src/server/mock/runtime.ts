import { randomBytes, randomUUID } from "node:crypto";
import { setTimeout as sleep } from "node:timers/promises";

import { cookies } from "next/headers";

import type { Permission } from "@/lib/permissions";
import { MOCK_SCENARIO_COOKIE, type MockScenario, isMockScenario } from "@/lib/mock-scenarios";
import type { ApprovalRequest, Problem, Result, StaffContext, StaffMember, Tokens } from "@/server/data/types";
import { env } from "@/server/env";

import { ROLE_DOMAINS, permissionsFor, type StaffFixture } from "./fixtures/staff";
import { type MockSession, type PendingAction, store } from "./state";

/**
 * Moteur du mock : latence, scénarios, sessions et jetons simulés, contrôle des permissions, step-up,
 * demandes à quatre yeux et journal d'audit. Reproduit les codes d'erreur du contrat.
 * Marqueur vérifié par la CI (absent du build de production) : omeo-admin-mock-data-source.
 */
export const MOCK_MARKER = "omeo-admin-mock-data-source";

const ACCESS_TTL_MS = 10 * 60 * 1000;
const STEP_UP_TTL_MS = 15 * 60 * 1000;
const MFA_CHALLENGE_TTL_MS = 5 * 60 * 1000;

export function problem(status: number, code: string, extra: Partial<Problem> = {}): Problem {
  return { type: `https://my-omeo.app/problems/${code}`, title: code, status, code, ...extra };
}

/** Scénario de démonstration choisi dans le bandeau (cookie, lu uniquement par le mock). */
export async function scenario(): Promise<MockScenario> {
  try {
    const value = (await cookies()).get(MOCK_SCENARIO_COOKIE)?.value;
    return isMockScenario(value) ? value : "normal";
  } catch {
    // Hors requête (tests unitaires) : scénario nominal.
    return "normal";
  }
}

async function latency(current: MockScenario): Promise<void> {
  const ms = current === "slow" ? Math.max(3000, env.MOCK_LATENCY_MS * 10) : env.MOCK_LATENCY_MS;
  if (ms > 0) await sleep(ms);
}

/** Erreur imposée par le scénario, avant tout traitement. */
function scenarioProblem(current: MockScenario): Problem | undefined {
  if (current === "server_error") return problem(500, "server_error");
  if (current === "rate_limited") return problem(429, "rate_limited", { meta: { retry_after: 30 } });
  if (current === "offline") return problem(503, "network_error");
  return undefined;
}

export async function ok<T>(data: T): Promise<Result<T>> {
  await latency(await scenario());
  return { ok: true, data };
}

export async function fail<T>(p: Problem): Promise<Result<T>> {
  await latency(await scenario());
  return { ok: false, problem: p };
}

const token = (kind: string) => `${MOCK_MARKER}.${kind}.${randomBytes(18).toString("base64url")}`;

export function issueTokens(session: MockSession): Tokens {
  session.access = token("access");
  session.accessExpiresAt = Date.now() + ACCESS_TTL_MS;
  session.refresh = token("refresh");
  return { access: session.access, refresh: session.refresh, access_expires_at: new Date(session.accessExpiresAt).toISOString() };
}

export function openSession(staffId: string, mfaVerified: boolean): Tokens {
  const session: MockSession = {
    id: randomUUID(),
    staffId,
    access: "",
    accessExpiresAt: 0,
    refresh: "",
    usedRefresh: new Set(),
    mfaVerifiedAt: mfaVerified ? Date.now() : null,
  };
  store().sessions.set(session.id, session);
  return issueTokens(session);
}

export function createMfaChallenge(staffId: string): string {
  const id = token("mfa");
  store().mfaChallenges.set(id, { staffId, expiresAt: Date.now() + MFA_CHALLENGE_TTL_MS });
  return id;
}

export function findStaffByEmail(email: string): StaffFixture | undefined {
  return store().staff.find((s) => s.email.toLowerCase() === email.trim().toLowerCase());
}

export function staffById(id: string): StaffFixture | undefined {
  return store().staff.find((s) => s.id === id);
}

export function sessionByAccess(access: string): MockSession | undefined {
  for (const s of store().sessions.values()) if (s.access === access) return s;
  return undefined;
}

export function sessionByRefresh(refresh: string): { session: MockSession; reused: boolean } | undefined {
  for (const s of store().sessions.values()) {
    if (s.refresh === refresh) return { session: s, reused: false };
    if (s.usedRefresh.has(refresh)) return { session: s, reused: true };
  }
  return undefined;
}

export type Actor = { staff: StaffFixture; session: MockSession; permissions: Permission[] };

/** Vue « API » d'un membre : permissions effectives, fin du step-up, demandes à valider. */
export function staffMember(staff: StaffFixture, session?: MockSession): StaffMember {
  const permissions = permissionsFor(staff.roles);
  const verifiedUntil =
    session?.mfaVerifiedAt && session.mfaVerifiedAt + STEP_UP_TTL_MS > Date.now()
      ? new Date(session.mfaVerifiedAt + STEP_UP_TTL_MS).toISOString()
      : null;
  return {
    ...staff,
    permissions,
    mfa_verified_until: session ? verifiedUntil : null,
    pending_approvals: permissions.includes("approvals.decide") ? pendingFor(staff).length : 0,
  };
}

/** Demandes en attente qu'une personne peut décider (son domaine, jamais les siennes). */
export function pendingFor(staff: StaffFixture): ApprovalRequest[] {
  const domains = new Set(staff.roles.flatMap((r) => ROLE_DOMAINS[r]));
  return store().approvals.filter(
    (a) => a.status === "pending" && domains.has(a.domain) && store().approvalAuthors.get(a.id) !== staff.id,
  );
}

type Guard = { permission?: Permission | "authenticated_staff"; stepUp?: boolean };

/**
 * Authentifie l'appel et applique les contrôles de l'API, dans l'ordre : scénario, jeton (401),
 * enrôlement 2FA, permission (403 forbidden_role), step-up (401 step_up_required).
 */
export async function authorize(ctx: StaffContext, guard: Guard = {}): Promise<Actor | Problem> {
  const current = await scenario();
  const forced = scenarioProblem(current);
  if (forced) return forced;

  const session = sessionByAccess(ctx.accessToken);
  if (!session) return problem(401, "not_authenticated");
  if (session.accessExpiresAt <= Date.now()) return problem(401, "token_expired");
  const staff = staffById(session.staffId);
  if (!staff || !staff.active) return problem(401, "not_authenticated");

  // Compte invité dont la 2FA n'est pas encore enrôlée : seule la configuration est permise.
  const enrollmentOnly = !staff.mfa_enabled && guard.permission !== "authenticated_staff";
  if (enrollmentOnly) return problem(403, "forbidden", { detail: "mfa_enrollment_required" });

  const permissions = permissionsFor(staff.roles);
  if (guard.permission && guard.permission !== "authenticated_staff" && !permissions.includes(guard.permission)) {
    return problem(403, "forbidden_role", { meta: { permission: guard.permission } });
  }
  const stepUpValid = session.mfaVerifiedAt !== null && session.mfaVerifiedAt + STEP_UP_TTL_MS > Date.now();
  if (guard.stepUp && (current === "step_up" || !stepUpValid)) {
    return problem(401, "step_up_required");
  }
  return { staff, session, permissions };
}

export function isProblem(value: unknown): value is Problem {
  return typeof value === "object" && value !== null && "code" in value && "status" in value && "title" in value;
}

/** Exécute une opération protégée : contrôles de l'API, puis traitement (donnée ou problème). */
export async function run<T>(
  ctx: StaffContext,
  guard: Guard,
  handler: (actor: Actor) => T | Problem,
): Promise<Result<T>> {
  const actor = await authorize(ctx, guard);
  if (isProblem(actor)) return fail(actor);
  const outcome = handler(actor);
  return isProblem(outcome) ? fail(outcome) : ok(outcome);
}

/** Pagination simulée (page et page_size du contrat, 25 par défaut). */
export function paginate<T>(items: T[], query: { page?: number; page_size?: number }) {
  const page = Math.max(1, query.page ?? 1);
  const pageSize = Math.min(200, Math.max(1, query.page_size ?? 25));
  return { results: items.slice((page - 1) * pageSize, page * pageSize), count: items.length, page, page_size: pageSize };
}

/** Recherche simple insensible à la casse et aux accents. */
export function matches(query: string | undefined, ...fields: (string | null | undefined)[]): boolean {
  if (!query) return true;
  const fold = (v: string) => v.normalize("NFD").replace(/\p{Diacritic}/gu, "").toLowerCase();
  const q = fold(query.trim());
  return fields.some((f) => f !== null && f !== undefined && fold(f).includes(q));
}

/** Tri simulé selon `ordering` (« champ » ou « -champ »). */
export function order<T>(items: T[], ordering: string | undefined, fallback: string): T[] {
  const spec = ordering || fallback;
  const desc = spec.startsWith("-");
  const key = desc ? spec.slice(1) : spec;
  return [...items].sort((a, b) => {
    const va = (a as Record<string, unknown>)[key];
    const vb = (b as Record<string, unknown>)[key];
    const cmp = String(va ?? "").localeCompare(String(vb ?? ""), "fr", { numeric: true });
    return desc ? -cmp : cmp;
  });
}

/** Entrée du journal d'audit (ajout seul), comme le ferait l'API. */
export function audit(
  actor: StaffFixture,
  action: string,
  target: { type: string; id: string },
  before: Record<string, unknown> | null,
  after: Record<string, unknown> | null,
): void {
  store().audit.unshift({
    id: randomUUID(),
    actor: actor.name ?? actor.email,
    action,
    target_type: target.type,
    target_id: target.id,
    before,
    after,
    ip: "127.0.0.1",
    created_at: new Date().toISOString(),
  });
}

/** Les domaines où la validation à quatre yeux est temporairement désactivée (réglage four_eyes). */
export function fourEyesEnabled(domain: ApprovalRequest["domain"]): boolean {
  return store().settings.four_eyes?.[domain] !== false;
}

/** Crée une demande de validation par une autre personne (réponse 202 de l'API). */
export function requestApproval(
  actor: StaffFixture,
  input: Pick<ApprovalRequest, "kind" | "domain" | "summary" | "target_type" | "target_id" | "diff" | "reason">,
  apply: PendingAction,
): ApprovalRequest | Problem {
  const duplicate = store().approvals.find(
    (a) => a.status === "pending" && a.kind === input.kind && a.target_id === input.target_id,
  );
  if (duplicate) return problem(409, "approval_pending", { meta: { approval_id: duplicate.id } });
  const now = Date.now();
  const approval: ApprovalRequest = {
    id: randomUUID(),
    status: "pending",
    requested_by: actor.name ?? actor.email,
    decided_by: null,
    decision_comment: null,
    created_at: new Date(now).toISOString(),
    decided_at: null,
    expires_at: new Date(now + 7 * 86_400_000).toISOString(),
    ...input,
  };
  store().approvals.unshift(approval);
  store().approvalAuthors.set(approval.id, actor.id);
  store().approvalActions.set(approval.id, apply);
  audit(actor, "approvals.request", { type: "approval", id: approval.id }, null, { kind: input.kind, summary: input.summary });
  return approval;
}
