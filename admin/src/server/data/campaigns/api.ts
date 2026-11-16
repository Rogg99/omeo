import "server-only";

import { api, authed, call, callApplied, paged } from "../http";
import type { CampaignsRepository } from ".";

export const campaignsApi: CampaignsRepository = {
  list: (query, ctx) => paged(() => api.GET("/admin/campaigns", { params: { query }, ...authed(ctx) })),
  get: (id, ctx) => call(() => api.GET("/admin/campaigns/{id}", { params: { path: { id } }, ...authed(ctx) })),
  create: (body, ctx) => call(() => api.POST("/admin/campaigns", { body, ...authed(ctx) })),
  update: (id, body, ctx) =>
    call(() => api.PATCH("/admin/campaigns/{id}", { params: { path: { id } }, body, ...authed(ctx) })),
  audience: (body, ctx) => call(() => api.POST("/admin/campaigns/audience", { body, ...authed(ctx) })),
  action: (id, action, ctx) =>
    callApplied(() => api.POST("/admin/campaigns/{id}/{action}", { params: { path: { id, action } }, ...authed(ctx) })),
};
