import type { ApprovalRequest, BodyOf, Page, QueryOf, Result, StaffContext } from "../types";

export type ApprovalsQuery = QueryOf<"adminListApprovals">;
export type DecisionInput = BodyOf<"adminDecideApproval">;

export interface ApprovalsRepository {
  /** Demandes à traiter (domaines de la personne) ou, avec `mine`, demandes émises. */
  list(query: ApprovalsQuery, ctx: StaffContext): Promise<Result<Page<ApprovalRequest>>>;
  /** Step-up ; jamais sa propre demande (403 `self_approval_forbidden`). */
  decide(id: string, input: DecisionInput, ctx: StaffContext): Promise<Result<ApprovalRequest>>;
  /** Annule sa propre demande en attente. */
  cancel(id: string, ctx: StaffContext): Promise<Result<ApprovalRequest>>;
}
