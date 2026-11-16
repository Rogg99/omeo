import "server-only";

import { api, authed, call } from "../http";
import type { DashboardRepository } from ".";

export const dashboardApi: DashboardRepository = {
  get: (query, ctx) => call(() => api.GET("/admin/dashboard", { params: { query }, ...authed(ctx) })),
};
