import "server-only";

import { api, authed, call, callApplied, callEmpty, paged } from "../http";
import type { ContentRepository } from ".";

export const contentApi: ContentRepository = {
  list: (type, query, ctx) =>
    paged(() => api.GET("/admin/content/{type}", { params: { path: { type }, query }, ...authed(ctx) })),
  get: (type, id, ctx) =>
    call(() => api.GET("/admin/content/{type}/{id}", { params: { path: { type, id } }, ...authed(ctx) })),
  create: (type, body, ctx) =>
    call(() => api.POST("/admin/content/{type}", { params: { path: { type } }, body, ...authed(ctx) })),
  update: (type, id, body, ctx) =>
    call(() => api.PATCH("/admin/content/{type}/{id}", { params: { path: { type, id } }, body, ...authed(ctx) })),
  remove: (type, id, ctx) =>
    callEmpty(() => api.DELETE("/admin/content/{type}/{id}", { params: { path: { type, id } }, ...authed(ctx) })),
  transition: (type, id, body, ctx) =>
    callApplied(() =>
      api.POST("/admin/content/{type}/{id}/transition", { params: { path: { type, id } }, body, ...authed(ctx) }),
    ),
  revisions: (type, id, ctx) =>
    call(() => api.GET("/admin/content/{type}/{id}/revisions", { params: { path: { type, id } }, ...authed(ctx) })),
  translate: (type, id, locales, ctx) =>
    call(() =>
      api.POST("/admin/content/{type}/{id}/translate", {
        params: { path: { type, id } },
        body: { locales },
        ...authed(ctx),
      }),
    ),
  coverage: (ctx) => call(() => api.GET("/admin/translations", authed(ctx))),
  createUpload: (body, ctx) => call(() => api.POST("/admin/media", { body, ...authed(ctx) })),
};
