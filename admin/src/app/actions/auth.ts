"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import QRCode from "qrcode";
import { z } from "zod";

import type { ActionResult } from "@/lib/action-result";
import { MOCK_SCENARIO_COOKIE, MOCK_SCENARIOS } from "@/lib/mock-scenarios";
import { publicAction, staffAction, toActionProblem } from "@/server/action";
import source from "@/server/data/source";
import { clearSession, ensureSession, requestContext, writeSession } from "@/server/session";
import { COOKIES, cookieOptions, safeNextPath } from "@/server/session-cookies";

/**
 * Connexion de l'équipe : email et mot de passe, puis second facteur (TOTP ou code de secours).
 * Le jeton intermédiaire du second facteur vit dans un cookie httpOnly de 5 minutes.
 */

const MFA_COOKIE_MAX_AGE_S = 5 * 60;
const code = z
  .string()
  .trim()
  .regex(/^[0-9A-Za-z-]{6,12}$/);

const loginSchema = z.object({
  email: z.email().max(254),
  password: z.string().min(1).max(128),
  next: z.string().max(512).optional(),
});

export async function login(raw: unknown): Promise<ActionResult<null>> {
  const parsed = await publicAction(raw, loginSchema);
  if (!parsed.ok) return parsed;
  const { email, password, next } = parsed.data;
  const result = await source.auth.login(email, password, await requestContext());
  if (!result.ok) return { ok: false, problem: toActionProblem(result.problem) };
  const store = await cookies();
  const destination = safeNextPath(next);
  if (result.data.kind === "mfa") {
    store.set(COOKIES.mfa, result.data.mfaToken, cookieOptions(MFA_COOKIE_MAX_AGE_S));
    redirect(`/login/mfa?next=${encodeURIComponent(destination)}`);
  }
  // Compte sans double authentification : session limitée à l'enrôlement.
  await writeSession(store, result.data.tokens);
  redirect("/enroll");
}

export async function verifyMfa(raw: unknown): Promise<ActionResult<null>> {
  const parsed = await publicAction(raw, z.object({ code, next: z.string().max(512).optional() }));
  if (!parsed.ok) return parsed;
  const store = await cookies();
  const mfaToken = store.get(COOKIES.mfa)?.value;
  if (!mfaToken) return { ok: false, problem: { status: 401, code: "token_expired" } };
  const result = await source.auth.verifyMfa(mfaToken, parsed.data.code, await requestContext());
  if (!result.ok) return { ok: false, problem: toActionProblem(result.problem) };
  store.delete({ name: COOKIES.mfa, path: "/" });
  await writeSession(store, result.data);
  redirect(safeNextPath(parsed.data.next));
}

export async function forgotPassword(raw: unknown): Promise<ActionResult<null>> {
  const parsed = await publicAction(raw, z.object({ email: z.email().max(254) }));
  if (!parsed.ok) return parsed;
  const result = await source.auth.forgotPassword(parsed.data.email, await requestContext());
  // Réponse identique que le compte existe ou non (pas d'énumération).
  return result.ok || result.problem.status !== 429 ? { ok: true, data: null } : { ok: false, problem: toActionProblem(result.problem) };
}

export type Enrollment = { qrSvg: string; secret: string; recoveryCodes: string[] };

export async function startEnrollment(raw: unknown): Promise<ActionResult<Enrollment>> {
  return staffAction(
    raw,
    z.object({}),
    async (_input, ctx) => {
      const result = await source.auth.setupMfa(undefined, ctx);
      if (!result.ok) return result;
      const uri = result.data.otpauth_uri ?? "";
      const secret = new URL(uri).searchParams.get("secret") ?? "";
      const qrSvg = await QRCode.toString(uri, { type: "svg", margin: 0, errorCorrectionLevel: "M" });
      return { ok: true, data: { qrSvg, secret, recoveryCodes: result.data.recovery_codes ?? [] } };
    },
    { refreshPage: false },
  );
}

export async function confirmEnrollment(raw: unknown): Promise<ActionResult<null>> {
  const result = await staffAction(
    raw,
    z.object({ code }),
    async ({ code: value }, ctx) => {
      const r = await source.auth.setupMfa(value, ctx);
      return r.ok ? { ok: true, data: null } : r;
    },
    { refreshPage: false },
  );
  if (result.ok) redirect("/");
  return result;
}

/** Revalidation TOTP pour les actions sensibles (15 minutes). */
export async function stepUp(raw: unknown): Promise<ActionResult<{ mfa_verified_until: string }>> {
  return staffAction(raw, z.object({ code }), (input, ctx) => source.auth.stepUp(input.code, ctx));
}

export async function logout(raw: unknown): Promise<void> {
  const parsed = await publicAction(raw, z.object({}));
  const store = await cookies();
  if (parsed.ok) {
    const ctx = await ensureSession();
    if (ctx) await source.auth.logout(ctx);
  }
  clearSession(store);
  redirect("/login");
}

// ── Mode démonstration (mock uniquement) ──────────────────────────────────────

/** Change de compte de démo : nouvelle connexion simulée, code TOTP fixe. */
export async function switchDemoAccount(raw: unknown): Promise<ActionResult<null>> {
  if (!source.demo) return { ok: false, problem: { status: 404, code: "not_found" } };
  const parsed = await publicAction(raw, z.object({ email: z.email(), next: z.string().max(512).optional() }));
  if (!parsed.ok) return parsed;
  const ctx = await requestContext();
  const { DEMO_PASSWORD_HINT, DEMO_CODE_HINT } = DEMO;
  const login = await source.auth.login(parsed.data.email, DEMO_PASSWORD_HINT, ctx);
  if (!login.ok) return { ok: false, problem: toActionProblem(login.problem) };
  const store = await cookies();
  const tokens =
    login.data.kind === "session" ? login.data.tokens : await source.auth.verifyMfa(login.data.mfaToken, DEMO_CODE_HINT, ctx).then((r) => (r.ok ? r.data : null));
  if (!tokens) return { ok: false, problem: { status: 401, code: "invalid_credentials" } };
  await writeSession(store, tokens);
  redirect(login.data.kind === "session" ? "/enroll" : safeNextPath(parsed.data.next));
}

export async function setDemoScenario(raw: unknown): Promise<ActionResult<null>> {
  if (!source.demo) return { ok: false, problem: { status: 404, code: "not_found" } };
  const parsed = await publicAction(raw, z.object({ scenario: z.enum(MOCK_SCENARIOS) }));
  if (!parsed.ok) return parsed;
  (await cookies()).set(MOCK_SCENARIO_COOKIE, parsed.data.scenario, cookieOptions());
  return { ok: true, data: null };
}

/** Identifiants publics de la démo, affichés dans le bandeau du mode mock. */
const DEMO = { DEMO_PASSWORD_HINT: "omeo-demo-2026", DEMO_CODE_HINT: "000000" } as const;
