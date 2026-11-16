import "server-only";

import { api, authed, call, callApplied, paged } from "../http";
import type { BillingRepository } from ".";

export const billingApi: BillingRepository = {
  plans: (ctx) => call(() => api.GET("/admin/plans", authed(ctx))),
  updatePlan: (code, body, ctx) =>
    callApplied(() => api.PATCH("/admin/plans/{code}", { params: { path: { code } }, body, ...authed(ctx) })),
  quotas: (ctx) => call(() => api.GET("/admin/quotas", authed(ctx))),
  replaceQuotas: (body, ctx) => callApplied(() => api.PUT("/admin/quotas", { body, ...authed(ctx) })),
  subscriptions: (query, ctx) =>
    paged(() => api.GET("/admin/subscriptions", { params: { query }, ...authed(ctx) })),
  payments: (query, ctx) => paged(() => api.GET("/admin/payments", { params: { query }, ...authed(ctx) })),
  refund: (id, body, ctx) =>
    callApplied(() => api.POST("/admin/payments/{id}/refund", { params: { path: { id } }, body, ...authed(ctx) })),
  promoCodes: (query, ctx) => paged(() => api.GET("/admin/promo-codes", { params: { query }, ...authed(ctx) })),
  createPromo: (body, ctx) => call(() => api.POST("/admin/promo-codes", { body, ...authed(ctx) })),
  updatePromo: (id, body, ctx) =>
    call(() => api.PATCH("/admin/promo-codes/{id}", { params: { path: { id } }, body, ...authed(ctx) })),
};
