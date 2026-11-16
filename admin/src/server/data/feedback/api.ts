import "server-only";

import { api, authed, call, paged } from "../http";
import type { FeedbackRepository } from ".";

export const feedbackApi: FeedbackRepository = {
  list: (query, ctx) => paged(() => api.GET("/admin/feedback", { params: { query }, ...authed(ctx) })),
  get: (id, ctx) => call(() => api.GET("/admin/feedback/{id}", { params: { path: { id } }, ...authed(ctx) })),
  resolve: (id, body, ctx) =>
    call(() => api.POST("/admin/feedback/{id}/resolve", { params: { path: { id } }, body, ...authed(ctx) })),
  stats: (query, ctx) => call(() => api.GET("/admin/feedback/stats", { params: { query }, ...authed(ctx) })),
};
