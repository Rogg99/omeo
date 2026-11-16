import "server-only";

import { api, authed, call, paged } from "../http";
import type { SupportRepository } from ".";

export const supportApi: SupportRepository = {
  tickets: (query, ctx) => paged(() => api.GET("/admin/tickets", { params: { query }, ...authed(ctx) })),
  ticket: (id, ctx) => call(() => api.GET("/admin/tickets/{id}", { params: { path: { id } }, ...authed(ctx) })),
  update: (id, body, ctx) =>
    call(() => api.PATCH("/admin/tickets/{id}", { params: { path: { id } }, body, ...authed(ctx) })),
  reply: (id, body, ctx) =>
    call(() => api.POST("/admin/tickets/{id}/messages", { params: { path: { id } }, body, ...authed(ctx) })),
  templates: (ctx) => call(() => api.GET("/admin/reply-templates", authed(ctx))),
};
