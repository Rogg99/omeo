import type { Applied, Result, Schemas, StaffContext } from "../types";

export type Settings = Schemas["Settings"];

export interface SettingsRepository {
  get(ctx: StaffContext): Promise<Result<Settings>>;
  /** Step-up et motif ; quatre yeux si une constante `nutrition.*` change. */
  update(input: Settings, ctx: StaffContext): Promise<Result<Applied<Settings>>>;
}
