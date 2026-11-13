import { randomUUID } from "node:crypto";

import type { Locale } from "@/i18n/routing";

import type { Payment, PlanCode, SubscriptionState } from "../types";
import { accountById, initialPayments, PROMO_CODES, initialSubscription, planName, planPrice, webSubscription, type AccountFixture } from "./fixtures/accounts";
import { usd } from "./money";

/**
 * État simulé, conservé en mémoire pendant la session (une session par connexion) : les écritures
 * (paiement, résiliation) sont visibles jusqu'au redémarrage du serveur.
 */

/** Délai entre le retour du paiement et l'activation par le webhook de l'agrégateur. */
export const ACTIVATION_DELAY_MS = 4_000;
const CHECKOUT_TTL_MS = 30 * 60 * 1000;

type WebPlan = { plan: PlanCode; periodEnd: string; autoRenew: boolean };

type Session = {
  id: string;
  accountId: string;
  usedRefresh: Set<string>;
  webPlan?: WebPlan;
  pending?: { plan: PlanCode; activatesAt: number; amountCents?: number };
  extraPayments: { id: string; plan: PlanCode; paidAt: string; amountCents?: number }[];
};

export type Checkout = {
  id: string;
  sessionId: string;
  plan: PlanCode;
  promoCode?: string;
  successUrl: string;
  cancelUrl: string;
  createdAt: number;
};

type Store = {
  sessions: Map<string, Session>;
  checkouts: Map<string, Checkout>;
  deletionTokens: Set<string>;
  lastDeletionToken?: string;
  ticketCount: number;
};

const globalStore = globalThis as typeof globalThis & { __omeoMockStore?: Store };
const store: Store = (globalStore.__omeoMockStore ??= {
  sessions: new Map(),
  checkouts: new Map(),
  deletionTokens: new Set(),
  ticketCount: 10_233,
});

export function openSession(account: AccountFixture): Session {
  const session: Session = { id: randomUUID(), accountId: account.id, usedRefresh: new Set(), extraPayments: [] };
  store.sessions.set(session.id, session);
  return session;
}

export function session(id: string): Session | undefined {
  return store.sessions.get(id);
}

export function closeSession(id: string): void {
  store.sessions.delete(id);
}

export function sessionAccount(s: Session): AccountFixture {
  const account = accountById(s.accountId);
  if (!account) throw new Error(`Compte de démo inconnu : ${s.accountId}`);
  return account;
}

function addPeriod(plan: PlanCode, from: Date): string {
  const end = new Date(from);
  if (plan === "plus_annual") end.setUTCFullYear(end.getUTCFullYear() + 1);
  else end.setUTCMonth(end.getUTCMonth() + 1);
  return end.toISOString();
}

/** Applique l'activation simulée (webhook de l'agrégateur) quand son délai est écoulé. */
function settlePending(s: Session, now: number): void {
  if (!s.pending || now < s.pending.activatesAt) return;
  const paidAt = new Date(s.pending.activatesAt);
  s.webPlan = { plan: s.pending.plan, periodEnd: addPeriod(s.pending.plan, paidAt), autoRenew: true };
  s.extraPayments.unshift({ id: randomUUID(), plan: s.pending.plan, paidAt: paidAt.toISOString(), amountCents: s.pending.amountCents });
  s.pending = undefined;
}

export function subscriptionOf(s: Session, locale: Locale, now = Date.now()): SubscriptionState {
  settlePending(s, now);
  if (!s.webPlan) return initialSubscription(sessionAccount(s).scenario, locale);
  const state = webSubscription(s.webPlan.plan, locale, s.webPlan.periodEnd);
  if (!state.subscription) return state;
  return {
    ...state,
    subscription: {
      ...state.subscription,
      auto_renew: s.webPlan.autoRenew,
      status: s.webPlan.autoRenew ? "active" : "canceled",
    },
  };
}

export function paymentsOf(s: Session, locale: Locale): Payment[] {
  const extra: Payment[] = s.extraPayments.map((p) => ({
    id: p.id,
    channel: "web",
    description: planName(p.plan, locale),
    amount: p.amountCents === undefined ? planPrice(p.plan, locale) : usd(p.amountCents, locale),
    status: "succeeded",
    paid_at: p.paidAt,
    receipt_url: `https://example.com/receipts/${p.id}`,
  }));
  return [...extra, ...initialPayments(sessionAccount(s).scenario, locale)];
}

export function setAutoRenew(s: Session, autoRenew: boolean): boolean {
  if (s.webPlan) {
    s.webPlan.autoRenew = autoRenew;
    return true;
  }
  return false;
}

export function createCheckout(input: Omit<Checkout, "id" | "createdAt">): Checkout {
  const checkout: Checkout = { ...input, id: randomUUID(), createdAt: Date.now() };
  store.checkouts.set(checkout.id, checkout);
  return checkout;
}

export function checkout(id: string): Checkout | undefined {
  return store.checkouts.get(id);
}

export function isExpired(c: Checkout, now = Date.now()): boolean {
  return now - c.createdAt > CHECKOUT_TTL_MS;
}

export function completeCheckout(c: Checkout, outcome: "success" | "failure" | "abandon"): string {
  store.checkouts.delete(c.id);
  if (outcome === "success") {
    const s = session(c.sessionId);
    const discounted = c.promoCode ? PROMO_CODES[c.promoCode]?.[c.plan] : undefined;
    if (s) s.pending = { plan: c.plan, activatesAt: Date.now() + ACTIVATION_DELAY_MS, amountCents: discounted };
    return c.successUrl;
  }
  const url = new URL(c.cancelUrl);
  url.searchParams.set("status", outcome === "failure" ? "failed" : "canceled");
  return url.toString();
}

export function issueDeletionToken(): string {
  const token = randomUUID();
  store.deletionTokens.add(token);
  store.lastDeletionToken = token;
  return token;
}

export function consumeDeletionToken(token: string): boolean {
  return store.deletionTokens.delete(token);
}

export function nextTicketNumber(): string {
  store.ticketCount += 1;
  return `NY-${store.ticketCount}`;
}

export function lastDeletionToken(): string | undefined {
  return store.lastDeletionToken;
}
