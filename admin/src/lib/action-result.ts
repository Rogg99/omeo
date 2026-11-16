import type { components } from "@/lib/api/schema";

/**
 * Réponse d'une Server Action, partagée entre le serveur et le client. Les comportements se basent
 * uniquement sur le `code` des erreurs (problem+json), jamais sur leur texte.
 */
export type ApprovalRequest = components["schemas"]["ApprovalRequest"];

/** Sous-ensemble sérialisable du problème de l'API renvoyé au navigateur. */
export type ActionProblem = {
  status: number;
  code: string;
  detail?: string;
  /** Erreurs par champ (`validation_error`), clé = chemin du champ. */
  errors?: Record<string, string[]>;
  meta?: Record<string, unknown>;
};

export type ActionResult<T> =
  | { ok: true; data: T }
  | { ok: true; pending: ApprovalRequest }
  | { ok: false; problem: ActionProblem };

export function isPending<T>(r: ActionResult<T>): r is { ok: true; pending: ApprovalRequest } {
  return r.ok && "pending" in r;
}

/** Codes d'erreur que l'interface traite de façon spécifique. */
export const PROBLEM = {
  stepUpRequired: "step_up_required",
  forbiddenRole: "forbidden_role",
  selfApproval: "self_approval_forbidden",
  conflict: "conflict",
  approvalPending: "approval_pending",
  validation: "validation_error",
  notAuthenticated: "not_authenticated",
  tokenExpired: "token_expired",
  csrf: "csrf_failed",
} as const;
