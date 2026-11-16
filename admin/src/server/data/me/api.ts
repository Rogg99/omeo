import "server-only";

import { api, authed, call } from "../http";
import type { MeRepository } from ".";

export const meApi: MeRepository = {
  get: (ctx) => call(() => api.GET("/admin/me", authed(ctx))),
};
