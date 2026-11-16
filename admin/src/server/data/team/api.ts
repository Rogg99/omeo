import "server-only";

import { api, authed, call } from "../http";
import type { TeamRepository } from ".";

export const teamApi: TeamRepository = {
  list: (ctx) => call(() => api.GET("/admin/team", authed(ctx))),
  invite: (body, ctx) => call(() => api.POST("/admin/team", { body, ...authed(ctx) })),
  update: (id, body, ctx) => call(() => api.PATCH("/admin/team/{id}", { params: { path: { id } }, body, ...authed(ctx) })),
};
