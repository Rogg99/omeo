import "server-only";

import { api, authed, call, callApplied } from "../http";
import type { SettingsRepository } from ".";

export const settingsApi: SettingsRepository = {
  get: (ctx) => call(() => api.GET("/admin/settings", authed(ctx))),
  update: (body, ctx) => callApplied(() => api.PATCH("/admin/settings", { body, ...authed(ctx) })),
};
