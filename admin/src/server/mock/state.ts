import type { AuditEntry } from "@/server/data/audit";
import type { PaymentRow, Plan, PromoCode, QuotaRule, SubscriptionRow } from "@/server/data/billing";
import type { Campaign } from "@/server/data/campaigns";
import type { Revision } from "@/server/data/content";
import type { FeedbackDetail } from "@/server/data/feedback";
import type { Settings } from "@/server/data/settings";
import type { ReplyTemplate } from "@/server/data/support";
import type { ApprovalRequest } from "@/server/data/types";
import type { UserDetail, UserHealth } from "@/server/data/users";

import { PAYMENTS, PLANS, PROMO_CODES, QUOTAS, SUBSCRIPTIONS } from "./fixtures/billing";
import { CONTENT, type ContentSeed } from "./fixtures/content";
import { FEEDBACK } from "./fixtures/feedback";
import { AUDIT, CAMPAIGNS, SETTINGS } from "./fixtures/misc";
import { STAFF, type StaffFixture } from "./fixtures/staff";
import { REPLY_TEMPLATES, TICKETS, type TicketSeed } from "./fixtures/support";
import { HEALTH, USERS } from "./fixtures/users";

/**
 * État simulé, propre au processus de dev : les écritures (publier, rembourser, répondre…) restent
 * visibles jusqu'au redémarrage du serveur. Conservé sur globalThis pour survivre au rechargement
 * à chaud des modules.
 */

export type MockSession = {
  id: string;
  staffId: string;
  access: string;
  accessExpiresAt: number;
  refresh: string;
  /** Jetons de renouvellement déjà utilisés : leur rejeu révoque la session (détection de vol). */
  usedRefresh: Set<string>;
  mfaVerifiedAt: number | null;
};

export type ContentState = ContentSeed & { version: number };

/** Action différée d'une demande à quatre yeux, exécutée à l'approbation. */
export type PendingAction = () => void;

type Store = {
  sessions: Map<string, MockSession>;
  mfaChallenges: Map<string, { staffId: string; expiresAt: number }>;
  /** Enrôlement 2FA en cours ou terminé, par membre. */
  enrollment: Map<string, { confirmed: boolean }>;
  staff: StaffFixture[];
  users: UserDetail[];
  health: Record<string, UserHealth>;
  content: ContentState[];
  revisions: Map<string, Revision[]>;
  feedback: FeedbackDetail[];
  plans: Plan[];
  quotas: QuotaRule[];
  subscriptions: SubscriptionRow[];
  payments: PaymentRow[];
  promos: PromoCode[];
  tickets: TicketSeed[];
  templates: ReplyTemplate[];
  campaigns: Campaign[];
  settings: Settings;
  approvals: ApprovalRequest[];
  /** Auteur (id) de chaque demande : contrôle « jamais sa propre demande ». */
  approvalAuthors: Map<string, string>;
  approvalActions: Map<string, PendingAction>;
  audit: AuditEntry[];
};

function seed(): Store {
  const content = structuredClone(CONTENT).map((c) => ({ ...c, version: c.everPublished ? 3 : 1 }));
  return {
    sessions: new Map(),
    mfaChallenges: new Map(),
    enrollment: new Map(),
    staff: structuredClone(STAFF),
    users: structuredClone(USERS),
    health: structuredClone(HEALTH),
    content,
    revisions: new Map(
      content.map((c) => [
        c.id,
        Array.from({ length: c.version }, (_, i) => ({
          id: `${c.id.slice(0, 24)}${String(i + 1).padStart(12, "0")}`,
          author: i === c.version - 1 ? "Fatou Kane" : "Ibrahim Sow",
          created_at: new Date(Date.parse(c.updatedAt) - (c.version - 1 - i) * 86_400_000).toISOString(),
          snapshot: { version: i + 1, data: c.data },
        })).reverse(),
      ]),
    ),
    feedback: structuredClone(FEEDBACK),
    plans: structuredClone(PLANS),
    quotas: structuredClone(QUOTAS),
    subscriptions: structuredClone(SUBSCRIPTIONS),
    payments: structuredClone(PAYMENTS),
    promos: structuredClone(PROMO_CODES),
    tickets: structuredClone(TICKETS),
    templates: structuredClone(REPLY_TEMPLATES),
    campaigns: structuredClone(CAMPAIGNS),
    settings: structuredClone(SETTINGS),
    approvals: [],
    approvalAuthors: new Map(),
    approvalActions: new Map(),
    audit: structuredClone(AUDIT),
  };
}

const globalStore = globalThis as typeof globalThis & { __omeoAdminMock?: Store };

export function store(): Store {
  globalStore.__omeoAdminMock ??= seed();
  return globalStore.__omeoAdminMock;
}

/** Remet l'état à zéro (tests). */
export function resetStore(): void {
  globalStore.__omeoAdminMock = seed();
}
