import "server-only";

import { cacheLife, cacheTag } from "next/cache";

import type { Locale } from "@/i18n/routing";

import { CACHE_TAGS } from "../cache-tags";
import type { DataSource, LegalKind } from "../types";
import { api, authHeaders, call, callWithBody, headers, orThrow, requestInit, settle } from "./client";

/** Implémentation de la couche de données sur l'API réelle (DATA_SOURCE=api). */

async function cachedPlans(locale: Locale) {
  "use cache";
  cacheLife("content");
  cacheTag(CACHE_TAGS.plans);
  return orThrow(callWithBody(() => api.GET("/billing/plans", { headers: headers({ locale }), ...requestInit() })));
}

async function cachedFaq(locale: Locale) {
  "use cache";
  cacheLife("content");
  cacheTag(CACHE_TAGS.faq);
  return orThrow(
    callWithBody(() => api.GET("/faq", { params: { query: { audience: "web" } }, headers: headers({ locale }), ...requestInit() })),
  );
}

async function cachedLegal(locale: Locale, kind: LegalKind) {
  "use cache";
  cacheLife("content");
  cacheTag(CACHE_TAGS.legal, `${CACHE_TAGS.legal}:${kind}`);
  return orThrow(
    callWithBody(() => api.GET("/legal/{kind}", { params: { path: { kind } }, headers: headers({ locale }), ...requestInit() })),
  );
}

const source: DataSource = {
  captchaRequired: true,

  content: {
    plans: (locale) => settle(cachedPlans(locale)),
    faq: (locale) => settle(cachedFaq(locale)),
    legal: (locale, kind) => settle(cachedLegal(locale, kind)),
  },

  referral: {
    check: (code, ctx) => callWithBody(() => api.POST("/referral/check", { body: { code }, headers: headers(ctx), ...requestInit() })),
  },

  support: {
    createTicket: (input, idempotencyKey, ctx) =>
      callWithBody(() =>
        api.POST("/support/tickets", {
          body: input,
          params: { header: { "Idempotency-Key": idempotencyKey } },
          headers: headers(ctx),
          ...requestInit(),
        }),
      ),
  },

  accountDeletion: {
    request: async (email, captcha, ctx) => {
      const r = await call(() => api.POST("/account-deletion", { body: { email, captcha }, headers: headers(ctx), ...requestInit() }));
      return r.ok ? { ok: true, data: null } : r;
    },
    confirm: async (token, ctx) => {
      const r = await call(() => api.POST("/account-deletion/confirm", { body: { token }, headers: headers(ctx), ...requestInit() }));
      return r.ok ? { ok: true, data: null } : r;
    },
  },

  auth: {
    login: (email, password, ctx) =>
      callWithBody(() =>
        api.POST("/auth/login", { body: { email, password, device: { platform: "web" } }, headers: headers(ctx), ...requestInit() }),
      ),
    social: (provider, idToken, nonce, ctx) =>
      callWithBody(() =>
        api.POST("/auth/social", {
          body: { provider, id_token: idToken, ...(nonce ? { nonce } : {}), device: { platform: "web" } },
          headers: headers(ctx),
          ...requestInit(),
        }),
      ),
    refresh: (refresh, ctx) =>
      callWithBody(() => api.POST("/auth/refresh", { body: { refresh }, headers: headers(ctx), ...requestInit() })),
    logout: async (ctx) => {
      const r = await call(() => api.POST("/auth/logout", { body: {}, headers: authHeaders(ctx), ...requestInit() }));
      return r.ok ? { ok: true, data: null } : r;
    },
  },

  billing: {
    subscription: (ctx) => callWithBody(() => api.GET("/me/subscription", { headers: authHeaders(ctx), ...requestInit() })),
    payments: (cursor, ctx) =>
      callWithBody(() =>
        api.GET("/me/payments", { params: { query: cursor ? { cursor } : {} }, headers: authHeaders(ctx), ...requestInit() }),
      ),
    checkout: (input, idempotencyKey, ctx) =>
      callWithBody(() =>
        api.POST("/me/billing/checkout", {
          body: input,
          params: { header: { "Idempotency-Key": idempotencyKey } },
          headers: authHeaders(ctx),
          ...requestInit(),
        }),
      ),
    promoCheck: (input, ctx) =>
      callWithBody(() => api.POST("/me/billing/promo-check", { body: input, headers: authHeaders(ctx), ...requestInit() })),
    portal: (returnUrl, ctx) =>
      callWithBody(() =>
        api.POST("/me/billing/portal", { body: { return_url: returnUrl }, headers: authHeaders(ctx), ...requestInit() }),
      ),
  },
};

export default source;
