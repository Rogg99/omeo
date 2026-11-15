import "server-only";

import { setTimeout as sleep } from "node:timers/promises";

import type { Locale } from "@/i18n/routing";
import { env, siteOrigin } from "@/server/env";

import type { AuthedContext, DataSource, Problem, Result } from "../types";
import { ACCOUNTS, DEMO_PASSWORD, findAccount, me, planName, planPrice, PROMO_CODES, type AccountFixture } from "./fixtures/accounts";
import { contentFor } from "./fixtures/content";
import { usd } from "./money";
import { fieldError, problem } from "./problems";
import * as state from "./state";
import { decode, issue, MOCK_MARKER } from "./tokens";

/**
 * Implémentation simulée de la couche de données (DATA_SOURCE=mock) : mêmes formes et mêmes codes
 * d'erreur que l'API, latence configurable (MOCK_LATENCY_MS), un scénario par compte de démo.
 * Exclue du build de production par l'alias `@/server/data/source`.
 */

const SOCIAL_PREFIX = `${MOCK_MARKER}.social.`;

const INVITE_CODES: Record<string, { referrer: string | null; trialDays: number }> = {
  AWA2026: { referrer: "Awa", trialDays: 7 },
  KOFI7: { referrer: null, trialDays: 7 },
};

const latency = () => (env.MOCK_LATENCY_MS > 0 ? sleep(env.MOCK_LATENCY_MS) : Promise.resolve());

async function respond<T>(data: T): Promise<Result<T>> {
  await latency();
  return { ok: true, data };
}

async function fail<T>(p: Problem): Promise<Result<T>> {
  await latency();
  return { ok: false, problem: p };
}

/** Erreurs forcées par le scénario du compte (429, 500). */
function scenarioProblem(account: AccountFixture): Problem | undefined {
  if (account.scenario === "rate_limited") return problem(429, "rate_limited", { retry_after: 30 } as Partial<Problem>);
  if (account.scenario === "server_error") return problem(500, "server_error");
  return undefined;
}

type Authed = { session: NonNullable<ReturnType<typeof state.session>>; account: AccountFixture };

function authenticate(ctx: AuthedContext): Authed | Problem {
  const claims = decode(ctx.accessToken, "access");
  const s = claims && state.session(claims.sid);
  if (!s) return problem(401, claims ? "not_authenticated" : "token_expired");
  const account = state.sessionAccount(s);
  return scenarioProblem(account) ?? { session: s, account };
}

function isProblem(v: Authed | Problem): v is Problem {
  return "code" in v;
}

function signIn(account: AccountFixture, locale: Locale) {
  const s = state.openSession(account);
  const subscription = state.subscriptionOf(s, locale);
  return { tokens: issue(s.id), me: me(account, locale, subscription.entitlements), created: false };
}

function isSiteUrl(url: string): boolean {
  try {
    return new URL(url).origin === siteOrigin;
  } catch {
    return false;
  }
}

const source: DataSource = {
  captchaRequired: false,
  demoPassword: DEMO_PASSWORD,

  content: {
    plans: (locale) => {
      const c = contentFor(locale);
      return respond({
        plans: [
          { code: "free", name: c.planNames.free, price: usd(0, locale), interval: "none", featured: false },
          {
            code: "plus_annual",
            name: c.planNames.plus_annual,
            price: planPrice("plus_annual", locale),
            monthly_equivalent: usd(392, locale),
            savings_percent: 13,
            interval: "year",
            featured: true,
          },
          { code: "plus_monthly", name: c.planNames.plus_monthly, price: planPrice("plus_monthly", locale), interval: "month", featured: false },
        ],
        comparison: c.comparison,
      });
    },
    faq: (locale) => respond(contentFor(locale).faq),
    legal: (locale, kind) => {
      const doc = contentFor(locale).legal[kind];
      return doc ? respond({ kind, locale, ...doc }) : fail(problem(404, "not_found"));
    },
  },

  referral: {
    check: (code) => {
      const invite = INVITE_CODES[code.trim().toUpperCase()];
      return respond(
        invite
          ? { valid: true, referrer_first_name: invite.referrer, trial_days: invite.trialDays }
          : { valid: false, referrer_first_name: null, trial_days: 7 },
      );
    },
  },

  support: {
    createTicket: () => respond({ number: state.nextTicketNumber() }),
  },

  accountDeletion: {
    request: async (email) => {
      // Comme l'API : même réponse que le compte existe ou non ; le lien n'est émis que s'il existe.
      if (findAccount(email)) state.issueDeletionToken();
      return respond(null);
    },
    confirm: (token) =>
      state.consumeDeletionToken(token) ? respond(null) : fail(fieldError("token", "invalid", "Invalid or expired link")),
  },

  auth: {
    login: (email, password, ctx) => {
      const account = findAccount(email);
      if (!account || password !== DEMO_PASSWORD) return fail(problem(401, "invalid_credentials"));
      if (account.scenario === "rate_limited") return fail(problem(429, "rate_limited"));
      return respond(signIn(account, ctx.locale));
    },
    social: (_provider, idToken, _nonce, ctx) => {
      const account = idToken.startsWith(SOCIAL_PREFIX) ? findAccount(idToken.slice(SOCIAL_PREFIX.length)) : undefined;
      // Compte social sans compte Omeo : le site ne crée pas de compte (inscription dans l'app).
      if (!account) return fail(problem(idToken.startsWith(SOCIAL_PREFIX) ? 404 : 401, idToken.startsWith(SOCIAL_PREFIX) ? "not_found" : "invalid_credentials"));
      return respond(signIn(account, ctx.locale));
    },
    refresh: (refreshToken) => {
      const claims = decode(refreshToken, "refresh");
      const s = claims && state.session(claims.sid);
      if (!claims || !s) return fail(problem(401, "token_expired"));
      // Rotation : un jeton de renouvellement rejoué ferme la session (détection de vol).
      if (s.usedRefresh.has(claims.jti)) {
        state.closeSession(s.id);
        return fail(problem(401, "token_expired"));
      }
      s.usedRefresh.add(claims.jti);
      return respond(issue(s.id));
    },
    logout: (ctx) => {
      const claims = decode(ctx.accessToken, "access");
      if (claims) state.closeSession(claims.sid);
      return respond(null);
    },
  },

  billing: {
    subscription: (ctx) => {
      const a = authenticate(ctx);
      return isProblem(a) ? fail(a) : respond(state.subscriptionOf(a.session, ctx.locale));
    },
    payments: (_cursor, ctx) => {
      const a = authenticate(ctx);
      return isProblem(a) ? fail(a) : respond({ results: state.paymentsOf(a.session, ctx.locale), next_cursor: null });
    },
    checkout: (input, _idempotencyKey, ctx) => {
      const a = authenticate(ctx);
      if (isProblem(a)) return fail(a);
      if (!a.account.emailVerified) return fail(problem(403, "email_not_verified"));
      const sub = state.subscriptionOf(a.session, ctx.locale);
      if (!sub.web_checkout_allowed || sub.subscription?.channel === "web") return fail(problem(409, "conflict"));
      if (!isSiteUrl(input.success_url)) return fail(fieldError("success_url", "invalid", "Must be a site URL"));
      if (!isSiteUrl(input.cancel_url)) return fail(fieldError("cancel_url", "invalid", "Must be a site URL"));
      const promo = input.promo_code?.trim().toUpperCase();
      if (promo && !PROMO_CODES[promo]) return fail(fieldError("promo_code", "invalid", "Unknown promo code"));
      const c = state.createCheckout({
        sessionId: a.session.id,
        plan: input.plan_code,
        promoCode: promo,
        successUrl: input.success_url,
        cancelUrl: input.cancel_url,
      });
      const url = new URL(`/${ctx.locale}/subscription/mock-checkout`, siteOrigin);
      url.searchParams.set("session", c.id);
      return respond({ checkout_url: url.toString(), expires_at: new Date(c.createdAt + 30 * 60 * 1000).toISOString() });
    },
    promoCheck: (input, ctx) => {
      const a = authenticate(ctx);
      if (isProblem(a)) return fail(a);
      const discounted = PROMO_CODES[input.code.trim().toUpperCase()]?.[input.plan_code];
      if (discounted === undefined) return respond({ valid: false });
      return respond({
        valid: true,
        label: contentFor(ctx.locale).promoLabel,
        original: planPrice(input.plan_code, ctx.locale),
        discounted: usd(discounted, ctx.locale),
      });
    },
    portal: (returnUrl, ctx) => {
      const a = authenticate(ctx);
      if (isProblem(a)) return fail(a);
      if (state.subscriptionOf(a.session, ctx.locale).can_manage !== "web") return fail(problem(409, "conflict"));
      if (!isSiteUrl(returnUrl)) return fail(fieldError("return_url", "invalid", "Must be a site URL"));
      const url = new URL(`/${ctx.locale}/subscription/mock-portal`, siteOrigin);
      url.searchParams.set("return", returnUrl);
      return respond({ url: url.toString() });
    },
  },

  demo: {
    accounts: () => ACCOUNTS.map(({ email, scenario }) => ({ email, scenario })),
    checkoutSession: (id, locale) => {
      const c = state.checkout(id);
      if (!c) return undefined;
      const discounted = c.promoCode ? PROMO_CODES[c.promoCode]?.[c.plan] : undefined;
      return {
        id: c.id,
        planName: planName(c.plan, locale),
        amount: discounted === undefined ? planPrice(c.plan, locale) : usd(discounted, locale),
        expired: state.isExpired(c),
      };
    },
    completeCheckout: (id, outcome) => {
      const c = state.checkout(id);
      return c ? state.completeCheckout(c, outcome) : undefined;
    },
    setAutoRenew: (accessToken, autoRenew) => {
      const claims = decode(accessToken, "access");
      const s = claims && state.session(claims.sid);
      return s ? state.setAutoRenew(s, autoRenew) : false;
    },
    lastDeletionToken: () => state.lastDeletionToken(),
    socialIdToken: (accountEmail) => `${SOCIAL_PREFIX}${accountEmail ?? "inconnu@omeo.demo"}`,
  },
};

export default source;
