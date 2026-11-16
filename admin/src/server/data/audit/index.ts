import type { Page, QueryOf, Result, Schemas, StaffContext } from "../types";

export type AuditEntry = Schemas["AuditEntry"];
export type AuditQuery = QueryOf<"adminListAudit">;

export interface AuditRepository {
  list(query: AuditQuery, ctx: StaffContext): Promise<Result<Page<AuditEntry>>>;
}
