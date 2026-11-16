import "server-only";

import { api, authed, paged } from "../http";
import type { AuditRepository } from ".";

export const auditApi: AuditRepository = {
  list: (query, ctx) => paged(() => api.GET("/admin/audit", { params: { query }, ...authed(ctx) })),
};
