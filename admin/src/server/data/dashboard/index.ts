import type { QueryOf, Result, Schemas, StaffContext } from "../types";

export type Dashboard = Schemas["AdminDashboard"];
export type DashboardQuery = QueryOf<"adminDashboard">;

export interface DashboardRepository {
  /** GET /admin/dashboard : les blocs non autorisés pour la personne valent `null`. */
  get(query: DashboardQuery, ctx: StaffContext): Promise<Result<Dashboard>>;
}
