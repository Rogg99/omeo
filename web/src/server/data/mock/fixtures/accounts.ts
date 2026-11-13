import type { Locale } from "@/i18n/routing";

import type { DemoAccount, DemoScenario, Payment, PlanCode, Schemas, SubscriptionState } from "../../types";
import { usd } from "../money";
import { contentFor } from "./content";

/** Mot de passe commun des comptes de démonstration. */
export const DEMO_PASSWORD = "omeo-demo";

type AccountFixture = DemoAccount & {
  id: string;
  firstName: string;
  lastName: string;
  emailVerified: boolean;
};

/** Comptes de démo de la page Abonnement : un par état des maquettes. */
export const ACCOUNTS: readonly AccountFixture[] = [
  { id: "5b3e0c1a-7d1f-4a8e-9b10-000000000001", email: "essai@omeo.demo", scenario: "trial", firstName: "Franck", lastName: "Etape", emailVerified: true },
  { id: "5b3e0c1a-7d1f-4a8e-9b10-000000000002", email: "free@omeo.demo", scenario: "free", firstName: "Awa", lastName: "Diallo", emailVerified: true },
  { id: "5b3e0c1a-7d1f-4a8e-9b10-000000000003", email: "plus@omeo.demo", scenario: "plus_web", firstName: "Mireille", lastName: "Nkoulou", emailVerified: true },
  { id: "5b3e0c1a-7d1f-4a8e-9b10-000000000004", email: "store@omeo.demo", scenario: "plus_store", firstName: "Ousmane", lastName: "Sow", emailVerified: true },
  { id: "5b3e0c1a-7d1f-4a8e-9b10-000000000005", email: "echec@omeo.demo", scenario: "past_due", firstName: "Aya", lastName: "Kouassi", emailVerified: true },
  { id: "5b3e0c1a-7d1f-4a8e-9b10-000000000006", email: "nonverifie@omeo.demo", scenario: "unverified", firstName: "Kofi", lastName: "Mensah", emailVerified: false },
  { id: "5b3e0c1a-7d1f-4a8e-9b10-000000000007", email: "offert@omeo.demo", scenario: "granted", firstName: "Fatou", lastName: "Ndiaye", emailVerified: true },
  { id: "5b3e0c1a-7d1f-4a8e-9b10-000000000008", email: "trop@omeo.demo", scenario: "rate_limited", firstName: "Test", lastName: "429", emailVerified: true },
  { id: "5b3e0c1a-7d1f-4a8e-9b10-000000000009", email: "panne@omeo.demo", scenario: "server_error", firstName: "Test", lastName: "500", emailVerified: true },
];

export type { AccountFixture };

export function findAccount(email: string): AccountFixture | undefined {
  const normalized = email.trim().toLowerCase();
  return ACCOUNTS.find((a) => a.email === normalized);
}

export function accountById(id: string): AccountFixture | undefined {
  return ACCOUNTS.find((a) => a.id === id);
}

const PRICES: Record<PlanCode, number> = { plus_monthly: 449, plus_annual: 4699 };

/** Remise précalculée des codes promo de démo (−20 %), par offre. */
export const PROMO_CODES: Record<string, Record<PlanCode, number>> = {
  BIENVENUE20: { plus_monthly: 359, plus_annual: 3759 },
};

export function planPrice(plan: PlanCode, locale: Locale) {
  return usd(PRICES[plan], locale);
}

export function planName(plan: PlanCode, locale: Locale): string {
  return contentFor(locale).planNames[plan];
}

const FREE_FEATURES = {
  text_analysis: false,
  progress_long_range: false,
  programs: false,
  insights: false,
  offline_workouts: false,
  streak_freeze: false,
};
const PLUS_FEATURES = {
  text_analysis: true,
  progress_long_range: true,
  programs: true,
  insights: true,
  offline_workouts: true,
  streak_freeze: true,
};

const FREE_QUOTAS: Schemas["Quota"][] = [
  { feature: "photo_analysis", limit: 3, used: 1, remaining: 2, period: "day", resets_at: "2026-11-14T00:00:00Z" },
  { feature: "text_analysis", limit: 0, used: 0, remaining: 0, period: "day", resets_at: null },
  { feature: "challenges_active", limit: 1, used: 0, remaining: 1, period: "day", resets_at: null },
];
const PLUS_QUOTAS: Schemas["Quota"][] = [
  { feature: "photo_analysis", limit: 140, used: 12, remaining: 128, period: "month", resets_at: "2026-12-09T00:00:00Z" },
  { feature: "text_analysis", limit: 140, used: 3, remaining: 137, period: "month", resets_at: "2026-12-09T00:00:00Z" },
  { feature: "challenges_active", limit: null, used: 2, remaining: null, period: "month", resets_at: null },
];
const TRIAL_QUOTAS: Schemas["Quota"][] = [
  { feature: "photo_analysis", limit: 28, used: 9, remaining: 19, period: "trial", resets_at: null },
  { feature: "text_analysis", limit: 10, used: 2, remaining: 8, period: "trial", resets_at: null },
  { feature: "challenges_active", limit: 1, used: 1, remaining: 0, period: "trial", resets_at: null },
];

/** Abonnement web actif sur une offre : la fixture « après paiement ». */
export function webSubscription(plan: PlanCode, locale: Locale, periodEnd: string): SubscriptionState {
  return {
    entitlements: { tier: "plus", trial_ends_at: null, plus_until: periodEnd, features: PLUS_FEATURES },
    subscription: {
      plan_code: plan,
      plan_name: planName(plan, locale),
      channel: "web",
      status: "active",
      current_period_end: periodEnd,
      auto_renew: true,
      price: planPrice(plan, locale),
    },
    trial_days_left: null,
    granted_days_left: null,
    quotas: PLUS_QUOTAS,
    can_purchase_in_app: false,
    can_manage: "web",
    web_checkout_allowed: true,
  };
}

/** État d'abonnement initial de chaque scénario. */
export function initialSubscription(scenario: DemoScenario, locale: Locale): SubscriptionState {
  switch (scenario) {
    case "trial":
      return {
        entitlements: { tier: "trial", trial_ends_at: "2026-11-15T09:00:00Z", plus_until: null, features: PLUS_FEATURES },
        subscription: null,
        trial_days_left: 2,
        granted_days_left: null,
        quotas: TRIAL_QUOTAS,
        can_purchase_in_app: true,
        can_manage: "none",
        web_checkout_allowed: true,
      };
    case "plus_web":
      return webSubscription("plus_annual", locale, "2027-11-09T09:00:00Z");
    case "plus_store":
      return {
        entitlements: { tier: "plus", trial_ends_at: null, plus_until: "2026-12-14T09:00:00Z", features: PLUS_FEATURES },
        subscription: {
          plan_code: "plus_monthly",
          plan_name: planName("plus_monthly", locale),
          channel: "google_play",
          status: "active",
          current_period_end: "2026-12-14T09:00:00Z",
          auto_renew: true,
          price: planPrice("plus_monthly", locale),
        },
        trial_days_left: null,
        granted_days_left: null,
        quotas: PLUS_QUOTAS,
        can_purchase_in_app: false,
        can_manage: "store",
        web_checkout_allowed: false,
      };
    case "past_due": {
      const state = webSubscription("plus_monthly", locale, "2026-11-20T09:00:00Z");
      return { ...state, subscription: state.subscription ? { ...state.subscription, status: "grace" } : null };
    }
    case "granted":
      return {
        entitlements: { tier: "plus", trial_ends_at: null, plus_until: "2026-11-27T09:00:00Z", features: PLUS_FEATURES },
        subscription: {
          plan_code: "grant",
          plan_name: "Omeo Plus",
          channel: "grant",
          status: "active",
          current_period_end: "2026-11-27T09:00:00Z",
          auto_renew: false,
        },
        trial_days_left: null,
        granted_days_left: 14,
        quotas: PLUS_QUOTAS,
        can_purchase_in_app: true,
        can_manage: "none",
        web_checkout_allowed: true,
      };
    case "free":
    case "unverified":
    case "rate_limited":
    case "server_error":
      return {
        entitlements: { tier: "free", trial_ends_at: null, plus_until: null, features: FREE_FEATURES },
        subscription: null,
        trial_days_left: null,
        granted_days_left: null,
        quotas: FREE_QUOTAS,
        can_purchase_in_app: true,
        can_manage: "none",
        web_checkout_allowed: true,
      };
  }
}

/** Historique de paiements initial de chaque scénario. */
export function initialPayments(scenario: DemoScenario, locale: Locale): Payment[] {
  const name = (plan: PlanCode) => planName(plan, locale);
  switch (scenario) {
    case "plus_web":
      return [
        {
          id: "9c2d4e6f-1a3b-4c5d-8e7f-000000000002",
          channel: "web",
          description: name("plus_annual"),
          amount: planPrice("plus_annual", locale),
          status: "succeeded",
          paid_at: "2026-11-09T09:00:00Z",
          receipt_url: "https://example.com/receipts/omeo-demo-2",
        },
        {
          id: "9c2d4e6f-1a3b-4c5d-8e7f-000000000001",
          channel: "web",
          description: name("plus_monthly"),
          amount: planPrice("plus_monthly", locale),
          status: "succeeded",
          paid_at: "2026-10-09T09:00:00Z",
          receipt_url: "https://example.com/receipts/omeo-demo-1",
        },
      ];
    case "past_due":
      return [
        {
          id: "9c2d4e6f-1a3b-4c5d-8e7f-000000000004",
          channel: "web",
          description: name("plus_monthly"),
          amount: planPrice("plus_monthly", locale),
          status: "failed",
          paid_at: "2026-11-13T09:00:00Z",
          receipt_url: null,
        },
        {
          id: "9c2d4e6f-1a3b-4c5d-8e7f-000000000003",
          channel: "web",
          description: name("plus_monthly"),
          amount: planPrice("plus_monthly", locale),
          status: "succeeded",
          paid_at: "2026-10-13T09:00:00Z",
          receipt_url: "https://example.com/receipts/omeo-demo-3",
        },
      ];
    case "plus_store":
      return [
        {
          id: "9c2d4e6f-1a3b-4c5d-8e7f-000000000005",
          channel: "google_play",
          description: name("plus_monthly"),
          amount: planPrice("plus_monthly", locale),
          status: "succeeded",
          paid_at: "2026-11-14T09:00:00Z",
          receipt_url: null,
        },
      ];
    default:
      return [];
  }
}

/** Profil renvoyé à la connexion (forme exacte de `Me`). */
export function me(account: AccountFixture, locale: Locale, entitlements: Schemas["Entitlements"]): Schemas["Me"] {
  return {
    id: account.id,
    email: account.email,
    email_verified: account.emailVerified,
    has_password: true,
    locale,
    created_at: "2026-11-01T09:00:00Z",
    profile: {
      first_name: account.firstName,
      last_name: account.lastName,
      initials: `${account.firstName[0] ?? ""}${account.lastName[0] ?? ""}`,
      avatar: null,
      sex: "female",
      city: null,
      city_label: "Douala",
      height_cm: 168,
      current_weight_kg: 72,
      target_weight_kg: 66,
      goals: ["lose_weight"],
    },
    targets: { kcal: 1840, protein_g: 92, carbs_g: 220, fat_g: 61, fiber_g: 30, salt_max_g: 5, water_ml: 2000 },
    entitlements,
    preferences: { theme: "system", unit_weight: "kg", unit_height: "cm", unit_volume: "cl" },
  };
}
