import type { BodyOf, Result, StaffContext, StaffMember } from "../types";

export type InviteInput = BodyOf<"adminInviteStaff">;
export type StaffUpdate = BodyOf<"adminUpdateStaff">;

/** Toutes les opérations exigent `team.manage` et un step-up. */
export interface TeamRepository {
  list(ctx: StaffContext): Promise<Result<StaffMember[]>>;
  invite(input: InviteInput, ctx: StaffContext): Promise<Result<StaffMember>>;
  update(id: string, input: StaffUpdate, ctx: StaffContext): Promise<Result<StaffMember>>;
}
