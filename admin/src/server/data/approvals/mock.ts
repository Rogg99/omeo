import "server-only";

import { audit, paginate, pendingFor, problem, run } from "@/server/mock/runtime";
import { store } from "@/server/mock/state";

import type { ApprovalsRepository } from ".";

/** Les demandes expirent au bout de 7 jours. */
function expire() {
  const now = new Date().toISOString();
  for (const a of store().approvals) if (a.status === "pending" && a.expires_at <= now) a.status = "expired";
}

export const approvalsMock: ApprovalsRepository = {
  list: (query, ctx) =>
    run(ctx, { permission: "approvals.decide" }, ({ staff }) => {
      expire();
      const mine = store().approvals.filter((a) => store().approvalAuthors.get(a.id) === staff.id);
      const toDecide = query.status === "pending" || !query.status ? pendingFor(staff) : [];
      const decidable = new Set(pendingFor(staff).map((a) => a.id));
      const domainHistory = store().approvals.filter(
        (a) => a.status !== "pending" && store().approvalAuthors.get(a.id) !== staff.id && (decidable.has(a.id) || a.decided_by === staff.name),
      );
      const base = query.mine ? mine : query.status && query.status !== "pending" ? domainHistory : toDecide;
      return paginate(base.filter((a) => !query.status || a.status === query.status), query);
    }),

  decide: (id, input, ctx) =>
    run(ctx, { permission: "approvals.decide", stepUp: true }, ({ staff }) => {
      expire();
      const approval = store().approvals.find((a) => a.id === id);
      if (!approval) return problem(404, "not_found");
      if (store().approvalAuthors.get(id) === staff.id) return problem(403, "self_approval_forbidden");
      if (!pendingFor(staff).some((a) => a.id === id)) {
        return approval.status === "pending" ? problem(403, "forbidden_role") : problem(409, "conflict");
      }
      approval.status = input.decision === "approve" ? "approved" : "rejected";
      approval.decided_by = staff.name ?? staff.email;
      approval.decision_comment = input.comment ?? null;
      approval.decided_at = new Date().toISOString();
      if (input.decision === "approve") store().approvalActions.get(id)?.();
      store().approvalActions.delete(id);
      audit(staff, `approvals.${input.decision}`, { type: "approval", id }, { status: "pending" }, { status: approval.status, comment: input.comment ?? null });
      return approval;
    }),

  cancel: (id, ctx) =>
    run(ctx, { permission: "authenticated_staff" }, ({ staff }) => {
      const approval = store().approvals.find((a) => a.id === id);
      if (!approval || store().approvalAuthors.get(id) !== staff.id) return problem(404, "not_found");
      if (approval.status !== "pending") return problem(409, "conflict");
      approval.status = "canceled";
      approval.decided_at = new Date().toISOString();
      store().approvalActions.delete(id);
      audit(staff, "approvals.cancel", { type: "approval", id }, { status: "pending" }, { status: "canceled" });
      return approval;
    }),
};
