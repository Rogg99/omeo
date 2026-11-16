import "server-only";

import { DEMO_PASSWORD, DEMO_RECOVERY_CODES, DEMO_TOTP } from "@/server/mock/fixtures/staff";
import {
  audit,
  authorize,
  createMfaChallenge,
  fail,
  findStaffByEmail,
  isProblem,
  issueTokens,
  ok,
  openSession,
  problem,
  scenario,
  sessionByAccess,
  sessionByRefresh,
  staffById,
} from "@/server/mock/runtime";
import { store } from "@/server/mock/state";

import type { AuthRepository } from ".";

const validCode = (code: string) => code === DEMO_TOTP || DEMO_RECOVERY_CODES.includes(code.toUpperCase());

export const authMock: AuthRepository = {
  async login(email, password) {
    if ((await scenario()) === "rate_limited") return fail(problem(429, "rate_limited", { meta: { retry_after: 30 } }));
    const staff = findStaffByEmail(email);
    if (!staff || password !== DEMO_PASSWORD) return fail(problem(401, "invalid_credentials"));
    if (!staff.active) return fail(problem(403, "account_suspended"));
    // Compte invité sans 2FA : session limitée à l'enrôlement (voir contracts/CHANGES.md).
    if (!staff.mfa_enabled) return ok({ kind: "session" as const, tokens: openSession(staff.id, false) });
    return ok({ kind: "mfa" as const, mfaToken: createMfaChallenge(staff.id) });
  },

  async verifyMfa(mfaToken, code) {
    const challenge = store().mfaChallenges.get(mfaToken);
    if (!challenge || challenge.expiresAt <= Date.now()) return fail(problem(401, "token_expired"));
    if (!validCode(code)) return fail(problem(401, "invalid_credentials", { detail: "invalid_mfa_code" }));
    store().mfaChallenges.delete(mfaToken);
    const staff = staffById(challenge.staffId);
    if (!staff) return fail(problem(401, "not_authenticated"));
    staff.last_login_at = new Date().toISOString();
    return ok(openSession(staff.id, true));
  },

  async refresh(refresh) {
    const found = sessionByRefresh(refresh);
    if (!found) return fail(problem(401, "not_authenticated"));
    if (found.reused) {
      store().sessions.delete(found.session.id);
      return fail(problem(401, "not_authenticated", { detail: "refresh_reused" }));
    }
    found.session.usedRefresh.add(refresh);
    return ok(issueTokens(found.session));
  },

  async logout(ctx) {
    const session = sessionByAccess(ctx.accessToken);
    if (session) store().sessions.delete(session.id);
    return ok(null);
  },

  async stepUp(code, ctx) {
    const actor = await authorize(ctx, { permission: "authenticated_staff" });
    if (isProblem(actor)) return fail(actor);
    if (!validCode(code)) return fail(problem(401, "invalid_credentials", { detail: "invalid_mfa_code" }));
    actor.session.mfaVerifiedAt = Date.now();
    return ok({ mfa_verified_until: new Date(Date.now() + 15 * 60 * 1000).toISOString() });
  },

  async setupMfa(code, ctx) {
    const actor = await authorize(ctx, { permission: "authenticated_staff" });
    if (isProblem(actor)) return fail(actor);
    const { staff, session } = actor;
    if (staff.mfa_enabled) return fail(problem(409, "conflict", { detail: "mfa_already_enabled" }));
    if (!code) {
      store().enrollment.set(staff.id, { confirmed: false });
      return ok({
        otpauth_uri: `otpauth://totp/Omeo%20Admin:${encodeURIComponent(staff.email)}?secret=JBSWY3DPEHPK3PXP&issuer=Omeo%20Admin&digits=6&period=30`,
        recovery_codes: DEMO_RECOVERY_CODES,
        confirmed: false,
      });
    }
    if (!store().enrollment.has(staff.id)) return fail(problem(409, "conflict", { detail: "mfa_setup_not_started" }));
    if (code !== DEMO_TOTP) {
      return fail(
        problem(422, "validation_error", { errors: { code: [{ code: "invalid", message: "Code incorrect" }] } }),
      );
    }
    staff.mfa_enabled = true;
    store().enrollment.set(staff.id, { confirmed: true });
    session.mfaVerifiedAt = Date.now();
    audit(staff, "team.mfa_enrolled", { type: "staff", id: staff.id }, { mfa_enabled: false }, { mfa_enabled: true });
    return ok({ confirmed: true });
  },

  async forgotPassword() {
    return ok(null);
  },
};
