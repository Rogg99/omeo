import type { RequestContext, ResponseOf, Result, StaffContext, Tokens } from "../types";

/** Connexion : le second facteur à saisir, ou une session directe (compte dont la 2FA reste à enrôler). */
export type LoginOutcome = { kind: "mfa"; mfaToken: string } | { kind: "session"; tokens: Tokens };
export type StepUp = ResponseOf<"stepUpMfa", 200>;
export type MfaSetup = ResponseOf<"adminSetupMfa", 200>;

export interface AuthRepository {
  /** POST /auth/login. Un compte staff enrôlé reçoit 401 `mfa_required` et `meta.mfa_token`. */
  login(email: string, password: string, ctx: RequestContext): Promise<Result<LoginOutcome>>;
  /** POST /auth/mfa/verify (TOTP ou code de secours). */
  verifyMfa(mfaToken: string, code: string, ctx: RequestContext): Promise<Result<Tokens>>;
  /** POST /auth/refresh (rotation ; le rejeu d'un ancien jeton révoque la session). */
  refresh(refresh: string, ctx: RequestContext): Promise<Result<Tokens>>;
  /** POST /auth/logout. */
  logout(ctx: StaffContext): Promise<Result<null>>;
  /** POST /auth/mfa/step-up : revalide le TOTP pour 15 min. */
  stepUp(code: string, ctx: StaffContext): Promise<Result<StepUp>>;
  /** POST /admin/mfa/setup : sans code, génère le secret ; avec un code, confirme l'enrôlement. */
  setupMfa(code: string | undefined, ctx: StaffContext): Promise<Result<MfaSetup>>;
  /** POST /auth/password/forgot : toujours accepté, sans révéler si le compte existe. */
  forgotPassword(email: string, ctx: RequestContext): Promise<Result<null>>;
}
