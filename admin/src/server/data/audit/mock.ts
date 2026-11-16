import "server-only";

import { paginate, run } from "@/server/mock/runtime";
import { store } from "@/server/mock/state";

import type { AuditRepository } from ".";

export const auditMock: AuditRepository = {
  list: (query, ctx) =>
    run(ctx, { permission: "audit.view" }, () => {
      const actor = query.actor_id ? store().staff.find((s) => s.id === query.actor_id)?.name : undefined;
      const rows = store()
        .audit.filter((e) => !query.actor_id || e.actor === actor)
        .filter((e) => !query.action || e.action.startsWith(query.action))
        .filter((e) => !query.target_type || e.target_type === query.target_type)
        .filter((e) => !query.target_id || e.target_id === query.target_id)
        .filter((e) => !query.from || e.created_at.slice(0, 10) >= query.from)
        .filter((e) => !query.to || e.created_at.slice(0, 10) <= query.to);
      return paginate(rows, query);
    }),
};
