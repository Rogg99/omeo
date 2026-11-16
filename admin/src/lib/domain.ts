import type { components } from "@/lib/api/schema";

/**
 * Valeurs énumérées du contrat utilisées par les filtres et les formulaires. Chaque liste est
 * vérifiée contre le type généré (`satisfies`) : si le contrat change, la compilation échoue.
 */
type S = components["schemas"];

export const TIERS = ["trial", "free", "plus"] as const satisfies readonly S["PlanTier"][];
export const USER_STATUSES = ["active", "suspended", "deletion_pending"] as const satisfies readonly S["AdminUserRow"]["status"][];
export const CHANNELS = ["google_play", "app_store", "web", "grant"] as const satisfies readonly S["Channel"][];
export const SUBSCRIPTION_STATUSES = ["trial", "active", "grace", "canceled", "expired", "refunded"] as const satisfies readonly S["SubscriptionStatus"][];
export const PAYMENT_STATUSES = ["succeeded", "failed", "refunded", "pending"] as const satisfies readonly S["Payment"]["status"][];
export const TICKET_STATUSES = ["new", "open", "waiting_user", "resolved", "closed"] as const satisfies readonly S["TicketStatus"][];
export const TICKET_CATEGORIES = ["question", "technical", "billing", "suggestion", "personal_data", "account_deletion"] as const satisfies readonly S["TicketCategory"][];
export const FEEDBACK_REASONS = ["wrong_dish", "missing_ingredient", "wrong_quantities", "other"] as const satisfies readonly S["FeedbackReason"][];
export const FEEDBACK_STATUSES = ["new", "handled", "ignored"] as const satisfies readonly S["AdminFeedbackRow"]["status"][];
export const STAFF_ROLES = ["superadmin", "content", "support", "finance", "moderation"] as const satisfies readonly S["StaffRole"][];
export const GOALS = ["lose_weight", "gain_muscle", "eat_balanced", "prevent_diabetes", "prevent_hypertension"] as const satisfies readonly S["Goal"][];
export const APPROVAL_STATUSES = ["pending", "approved", "rejected", "expired", "canceled"] as const satisfies readonly S["ApprovalRequest"]["status"][];
export const COUNTRIES = ["CM", "SN", "CI", "ML", "GH", "TG", "GA", "BF", "BJ", "FR"] as const;
