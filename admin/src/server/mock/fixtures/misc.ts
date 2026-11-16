import type { AuditEntry } from "@/server/data/audit";
import type { Campaign } from "@/server/data/campaigns";
import type { Dashboard } from "@/server/data/dashboard";
import type { Settings } from "@/server/data/settings";

/** Campagnes, réglages, tableau de bord et journal d'audit simulés (previews/admin). */

export const CAMPAIGNS: Campaign[] = [
  {
    id: "ca000000-0000-4000-8000-000000000001",
    status: "scheduled",
    title: { fr: "6 nouvelles recettes de chez nous 🍲", en: "6 new home-style recipes 🍲" },
    body: {
      fr: "Sauce gombo légère, yassa allégé… découvre-les et ajoute-les à ton journal en un geste.",
      en: "Light okra sauce, lighter yassa… discover them and add them to your log in one tap.",
    },
    deeplink: "omeo://recipes",
    image_upload_id: null,
    segment: { locales: [], countries: ["CM", "SN", "CI"], tiers: ["free"], goals: [], inactive_days_min: null },
    scheduled_at: "2026-11-18T18:00:00Z",
    audience_count: 18400,
    sent_count: 0,
    opened_count: 0,
    open_rate: null,
    created_by: "Fatou Kane",
    created_at: "2026-11-14T10:00:00Z",
  },
  {
    id: "ca000000-0000-4000-8000-000000000002",
    status: "sent",
    title: { fr: "Reviens marcher avec nous", en: "Come walk with us again" },
    body: { fr: "Le challenge 2 L d'eau t'attend.", en: "The 2 L water challenge is waiting for you." },
    deeplink: "omeo://challenges",
    image_upload_id: null,
    segment: { locales: ["fr", "en"], countries: [], tiers: [], goals: [], inactive_days_min: 14 },
    scheduled_at: "2026-11-02T17:00:00Z",
    audience_count: 9200,
    sent_count: 9104,
    opened_count: 1657,
    open_rate: 0.182,
    created_by: "Ibrahim Sow",
    created_at: "2026-10-30T10:00:00Z",
  },
  {
    id: "ca000000-0000-4000-8000-000000000003",
    status: "draft",
    title: { fr: "Essai : -30 % sur l'annuel" },
    body: { fr: "Profite de -30 % sur Plus annuel jusqu'à dimanche." },
    deeplink: "omeo://subscription",
    image_upload_id: null,
    segment: { locales: ["fr"], countries: [], tiers: ["trial"], goals: [], inactive_days_min: null },
    scheduled_at: null,
    audience_count: 0,
    sent_count: 0,
    opened_count: 0,
    open_rate: null,
    created_by: "Aïssatou Diop",
    created_at: "2026-11-15T10:00:00Z",
  },
];

export const SETTINGS: Settings = {
  four_eyes: { content: true, finance: true, settings: true },
  billing: { refund_approval_threshold_usd: 50 },
  nutrition: {
    activity_factor: 1.2,
    lose_weight_deficit: 0.18,
    gain_muscle_surplus: 0.12,
    min_kcal: { female: 1200, male: 1500 },
    protein_g_per_kg: { lose_weight: 1.8, gain_muscle: 2, eat_balanced: 1.4 },
    fat_ratio: { lose_weight: 0.28, gain_muscle: 0.25, eat_balanced: 0.3 },
    water_ml_per_kg: 33,
    water_ml_per_active_hour: 500,
    fiber_g: { female: 25, male: 34 },
    salt_max_g: 5,
    activity_bonus_ratio: 0.5,
    kcal_target_tolerance: 0.1,
  },
  ai: {
    vision_model: "google/gemini-2.5-flash",
    text_model: "openai/gpt-4.1-mini",
    translation_model: "openai/gpt-4.1-mini",
    prompt_version: "scan-v14",
    system_prompt:
      "Tu analyses une photo de repas d'Afrique de l'Ouest et centrale. Identifie le plat, ses composants et leurs grammages.",
    low_confidence_threshold: 0.6,
    monthly_budget_usd: 2500,
  },
  app: {
    min_version_android: "1.0.0",
    min_version_ios: "1.0.0",
    min_age: 16,
    active_locales: ["fr", "en", "es", "pt", "ar", "zh", "ja", "de"],
    features: { voice_input: true, programs: true, insights: true, web_payment_link: false, offline_workouts: true },
    web_checkout_countries: ["CM", "SN", "CI", "FR"],
  },
  trial: { default_days: 3, invite_days: 7 },
  referral: { days_per_referral: 7, cap_days: 35 },
  challenges: { default_success_threshold: 0.8 },
  notifications: { max_push_per_day: 3, default_quiet_start: "22:00", default_quiet_end: "07:00" },
};

const days = (values: number[]) =>
  values.map((value, i) => ({ date: `2026-11-${String(i + 3).padStart(2, "0")}`, value }));

/** Tableau de bord complet ; le mock met à null les blocs que la personne n'a pas le droit de voir. */
export const DASHBOARD: Dashboard = {
  signups: { total: 8412, delta_percent: 18, series: days([980, 1040, 1120, 1210, 1300, 1260, 1502, 1600, 1580, 1650, 1720, 1810, 1790, 1880]) },
  active_users: { dau: 6240, wau: 14820, mau: 21980 },
  retention: { d1: 0.62, d7: 0.38, d30: 0.21 },
  trial_to_plus_rate: 0.114,
  revenue_by_channel: [
    { channel: "google_play", amount: { amount_cents: 2204000, currency: "USD", formatted: "$22,040" } },
    { channel: "app_store", amount: { amount_cents: 1150000, currency: "USD", formatted: "$11,500" } },
    { channel: "web", amount: { amount_cents: 472000, currency: "USD", formatted: "$4,720" } },
  ],
  mrr: { amount_cents: 2487000, currency: "USD", formatted: "$24,870" },
  analyses: { total: 14230, delta_percent: 6.4, series: days([12100, 12400, 12800, 13050, 13100, 12900, 13300, 13600, 13900, 14000, 14100, 14050, 14180, 14230]) },
  ai_cost: { amount_cents: 7115, currency: "USD", formatted: "$71.15" },
  negative_feedback_rate: 0.078,
  support_pending: 12,
};

export const AUDIT: AuditEntry[] = [
  {
    id: "ad000000-0000-4000-8000-000000000005",
    actor: "Paul Mbarga",
    action: "users.view_health",
    target_type: "user",
    target_id: "8f2a1c10-0000-4000-8000-000000000001",
    before: null,
    after: { reason: "Demande #4821" },
    ip: "102.244.1.18",
    created_at: "2026-11-16T08:41:00Z",
  },
  {
    id: "ad000000-0000-4000-8000-000000000004",
    actor: "Nadège Ekoto",
    action: "billing.refund",
    target_type: "payment",
    target_id: "a1000000-0000-4000-8000-000000000401",
    before: { status: "succeeded" },
    after: { status: "refunded", amount_cents: 449, reason: "Double débit" },
    ip: "41.82.10.4",
    created_at: "2026-11-16T08:12:00Z",
  },
  {
    id: "ad000000-0000-4000-8000-000000000003",
    actor: "Aïssatou Diop",
    action: "settings.edit",
    target_type: "settings",
    target_id: "nutrition.min_kcal.female",
    before: { value: 1200 },
    after: { value: 1250 },
    ip: "102.244.1.10",
    created_at: "2026-11-16T07:50:00Z",
  },
  {
    id: "ad000000-0000-4000-8000-000000000002",
    actor: "Ibrahim Sow",
    action: "content.publish",
    target_type: "recipes",
    target_id: "c0a7e000-0000-4000-8000-000000000302",
    before: { version: 6 },
    after: { version: 7 },
    ip: "154.72.3.90",
    created_at: "2026-11-15T17:03:00Z",
  },
  {
    id: "ad000000-0000-4000-8000-000000000001",
    actor: "Paul Mbarga",
    action: "users.extend_trial",
    target_type: "user",
    target_id: "8f2a1c10-0000-4000-8000-000000000003",
    before: { trial_days_left: 0 },
    after: { trial_days_left: 3, reason: "Bug de quota" },
    ip: "102.244.1.18",
    created_at: "2026-11-15T15:40:00Z",
  },
];
