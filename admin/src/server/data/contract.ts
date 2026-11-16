/**
 * Contrat de la couche de données de l'admin. Deux implémentations, choisies au build par
 * DATA_SOURCE (alias `@/server/data/source`, voir next.config.ts) : api.ts (API réelle) et mock.ts
 * (données simulées). Server Components et Server Actions n'appellent que cette interface.
 */
import type { ApprovalsRepository } from "./approvals";
import type { AuditRepository } from "./audit";
import type { AuthRepository } from "./auth";
import type { BillingRepository } from "./billing";
import type { CampaignsRepository } from "./campaigns";
import type { ContentRepository } from "./content";
import type { DashboardRepository } from "./dashboard";
import type { FeedbackRepository } from "./feedback";
import type { MeRepository } from "./me";
import type { SettingsRepository } from "./settings";
import type { SupportRepository } from "./support";
import type { TeamRepository } from "./team";
import type { UsersRepository } from "./users";

export interface DataSource {
  /** Vrai en mode mock : bandeau « Données simulées » et sélecteur de scénario et de rôle. */
  readonly demo: boolean;
  /** Comptes de démonstration (mode mock), vide avec l'API réelle. */
  readonly demoAccounts: readonly { email: string; name: string; roles: readonly string[] }[];
  readonly auth: AuthRepository;
  readonly me: MeRepository;
  readonly dashboard: DashboardRepository;
  readonly users: UsersRepository;
  readonly content: ContentRepository;
  readonly feedback: FeedbackRepository;
  readonly billing: BillingRepository;
  readonly support: SupportRepository;
  readonly campaigns: CampaignsRepository;
  readonly settings: SettingsRepository;
  readonly team: TeamRepository;
  readonly approvals: ApprovalsRepository;
  readonly audit: AuditRepository;
}
