import "server-only";

import { api, authed, call, paged } from "../http";
import type { ApprovalsRepository } from ".";

export const approvalsApi: ApprovalsRepository = {
  list: (query, ctx) => paged(() => api.GET("/admin/approvals", { params: { query }, ...authed(ctx) })),
  decide: (id, body, ctx) =>
    call(() => api.POST("/admin/approvals/{id}/decision", { params: { path: { id } }, body, ...authed(ctx) })),
  cancel: (id, ctx) => call(() => api.POST("/admin/approvals/{id}/cancel", { params: { path: { id } }, ...authed(ctx) })),
};
