import type { Permission } from "@/lib/permissions";
import type { StaffMember, StaffRole } from "@/server/data/types";

/**
 * Comptes de démonstration (un par rôle) et correspondance rôles → permissions SIMULÉE.
 *
 * Cette table imite apps/accounts/permissions.py de l'API, pour que le mock renvoie la même liste
 * effective que GET /admin/me et les mêmes refus (403 forbidden_role). Elle n'existe que dans le
 * dossier mock : l'interface ne la lit jamais (elle n'utilise que `permissions` de /admin/me).
 */
const ROLE_PERMISSIONS: Record<StaffRole, readonly Permission[]> = {
  superadmin: [
    "dashboard.product",
    "dashboard.finance",
    "dashboard.support",
    "users.view",
    "users.view_health",
    "users.resend_verification",
    "users.send_password_reset",
    "users.extend_trial",
    "users.grant_plus_days",
    "users.reset_quota",
    "users.suspend",
    "users.export_data",
    "users.delete_data",
    "content.view",
    "content.edit",
    "content.publish",
    "content.translate",
    "feedback.view",
    "feedback.resolve",
    "billing.view",
    "billing.plans_edit",
    "billing.quotas_edit",
    "billing.refund",
    "billing.promo_manage",
    "support.view",
    "support.reply",
    "support.templates_manage",
    "campaigns.view",
    "campaigns.edit",
    "campaigns.schedule",
    "approvals.decide",
    "settings.view",
    "settings.edit",
    "team.manage",
    "audit.view",
  ],
  content: [
    "dashboard.product",
    "content.view",
    "content.edit",
    "content.publish",
    "content.translate",
    "feedback.view",
    "campaigns.view",
    "campaigns.edit",
    "campaigns.schedule",
    "approvals.decide",
    "settings.view",
  ],
  support: [
    "dashboard.product",
    "dashboard.support",
    "users.view",
    "users.view_health",
    "users.resend_verification",
    "users.send_password_reset",
    "users.extend_trial",
    "users.reset_quota",
    "content.view",
    "billing.view",
    "support.view",
    "support.reply",
    "support.templates_manage",
  ],
  finance: [
    "dashboard.product",
    "dashboard.finance",
    "users.view",
    "users.grant_plus_days",
    "users.reset_quota",
    "billing.view",
    "billing.plans_edit",
    "billing.quotas_edit",
    "billing.refund",
    "billing.promo_manage",
    "approvals.decide",
    "settings.view",
  ],
  moderation: ["dashboard.product", "content.view", "feedback.view", "feedback.resolve"],
};

/** Domaines des validations à quatre yeux par rôle (approvals.decide « sur son domaine »). */
export const ROLE_DOMAINS: Record<StaffRole, readonly ("content" | "finance" | "settings")[]> = {
  superadmin: ["content", "finance", "settings"],
  content: ["content"],
  support: [],
  finance: ["finance"],
  moderation: [],
};

export function permissionsFor(roles: readonly StaffRole[]): Permission[] {
  return [...new Set(roles.flatMap((r) => ROLE_PERMISSIONS[r]))];
}

/** Mot de passe commun aux comptes de démonstration ; code TOTP simulé : 000000. */
export const DEMO_PASSWORD = "omeo-demo-2026";
export const DEMO_TOTP = "000000";
export const DEMO_RECOVERY_CODES = ["OMEO-7K2D-9QXA", "OMEO-4M8P-2LZC", "OMEO-1R6T-8VWB", "OMEO-5N3H-6JYE"];

/** Membre simulé : les champs calculés par l'API (permissions, step-up, demandes) sont ajoutés à la lecture. */
export type StaffFixture = Omit<StaffMember, "permissions" | "mfa_verified_until" | "pending_approvals">;

export const STAFF: StaffFixture[] = [
  {
    id: "5b1f6a0e-2c11-4a5e-9d0e-0a1b2c3d4e01",
    email: "aissatou@my-omeo.app",
    name: "Aïssatou Diop",
    roles: ["superadmin"],
    mfa_enabled: true,
    active: true,
    last_login_at: "2026-11-16T08:58:00Z",
  },
  {
    id: "5b1f6a0e-2c11-4a5e-9d0e-0a1b2c3d4e02",
    email: "ibrahim@my-omeo.app",
    name: "Ibrahim Sow",
    roles: ["content", "moderation"],
    mfa_enabled: true,
    active: true,
    last_login_at: "2026-11-16T07:40:00Z",
  },
  {
    id: "5b1f6a0e-2c11-4a5e-9d0e-0a1b2c3d4e03",
    email: "fatou@my-omeo.app",
    name: "Fatou Kane",
    roles: ["content"],
    mfa_enabled: true,
    active: true,
    last_login_at: "2026-11-15T17:12:00Z",
  },
  {
    id: "5b1f6a0e-2c11-4a5e-9d0e-0a1b2c3d4e04",
    email: "paul@my-omeo.app",
    name: "Paul Mbarga",
    roles: ["support"],
    mfa_enabled: true,
    active: true,
    last_login_at: "2026-11-16T08:38:00Z",
  },
  {
    id: "5b1f6a0e-2c11-4a5e-9d0e-0a1b2c3d4e05",
    email: "nadege@my-omeo.app",
    name: "Nadège Ekoto",
    roles: ["finance"],
    mfa_enabled: true,
    active: true,
    last_login_at: "2026-11-13T10:05:00Z",
  },
  {
    id: "5b1f6a0e-2c11-4a5e-9d0e-0a1b2c3d4e07",
    email: "mariam@my-omeo.app",
    name: "Mariam Traoré",
    roles: ["moderation"],
    mfa_enabled: true,
    active: true,
    last_login_at: "2026-11-14T15:20:00Z",
  },
  {
    id: "5b1f6a0e-2c11-4a5e-9d0e-0a1b2c3d4e06",
    email: "nouveau@my-omeo.app",
    name: "Samuel Nguema",
    roles: ["support"],
    mfa_enabled: false,
    active: true,
    last_login_at: null,
  },
];
