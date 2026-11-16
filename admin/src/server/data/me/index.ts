import type { Result, StaffContext, StaffMember } from "../types";

export interface MeRepository {
  /** GET /admin/me : rôles, permissions effectives, fin du step-up, demandes à valider. */
  get(ctx: StaffContext): Promise<Result<StaffMember>>;
}
