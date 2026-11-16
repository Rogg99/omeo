/**
 * Autorisations de l'admin (docs/technique/controle-acces.md), partagées entre serveur et client.
 *
 * L'admin ne connaît PAS la correspondance rôles → permissions : il ne lit que la liste effective
 * renvoyée par GET /admin/me. Ce fichier ne contient que les noms des permissions du catalogue,
 * pour que le code soit vérifié par le typage (une faute de frappe ne compile pas).
 * L'API reste l'autorité : un 403 `forbidden_role` l'emporte toujours sur ce que l'admin affiche.
 */

export const PERMISSIONS = [
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
  "content.publish_own",
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
] as const;

export type Permission = (typeof PERMISSIONS)[number];

/** Ce que l'admin sait de la personne connectée (sous-ensemble de StaffMember). */
export type Grants = { readonly permissions?: readonly string[] | undefined };

export type Can = (permission: Permission) => boolean;

/** Fabrique `can(permission)` à partir de la liste effective de GET /admin/me. */
export function createCan(grants: Grants | null | undefined): Can {
  const granted = new Set(grants?.permissions ?? []);
  return (permission) => granted.has(permission);
}

/** Au moins une des permissions. */
export function canAny(can: Can, permissions: readonly Permission[]): boolean {
  return permissions.some((p) => can(p));
}

/** Toutes les permissions. */
export function canAll(can: Can, permissions: readonly Permission[]): boolean {
  return permissions.every((p) => can(p));
}

/** Action sur un compte utilisateur → permission requise (`users.<action>`, voir le contrat). */
export const USER_ACTION_PERMISSION = {
  suspend: "users.suspend",
  reactivate: "users.suspend",
  resend_verification: "users.resend_verification",
  send_password_reset: "users.send_password_reset",
  extend_trial: "users.extend_trial",
  grant_plus_days: "users.grant_plus_days",
  reset_quota: "users.reset_quota",
  export_data: "users.export_data",
  delete_data: "users.delete_data",
} as const satisfies Record<string, Permission>;

export type UserAction = keyof typeof USER_ACTION_PERMISSION;
