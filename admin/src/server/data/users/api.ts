import "server-only";

import { api, authed, call, paged } from "../http";
import type { UsersRepository } from ".";

export const usersApi: UsersRepository = {
  list: (query, ctx) => paged(() => api.GET("/admin/users", { params: { query }, ...authed(ctx) })),
  get: (id, ctx) => call(() => api.GET("/admin/users/{id}", { params: { path: { id } }, ...authed(ctx) })),
  revealHealth: (id, reason, ctx) =>
    call(() => api.GET("/admin/users/{id}/health", { params: { path: { id }, query: { reason } }, ...authed(ctx) })),
  action: (id, body, ctx) =>
    call(() => api.POST("/admin/users/{id}/actions", { params: { path: { id } }, body, ...authed(ctx) })),
};
