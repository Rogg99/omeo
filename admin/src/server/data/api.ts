import "server-only";

import { approvalsApi } from "./approvals/api";
import { auditApi } from "./audit/api";
import { authApi } from "./auth/api";
import { billingApi } from "./billing/api";
import { campaignsApi } from "./campaigns/api";
import { contentApi } from "./content/api";
import type { DataSource } from "./contract";
import { dashboardApi } from "./dashboard/api";
import { feedbackApi } from "./feedback/api";
import { meApi } from "./me/api";
import { settingsApi } from "./settings/api";
import { supportApi } from "./support/api";
import { teamApi } from "./team/api";
import { usersApi } from "./users/api";

/** Couche de données sur l'API réelle (DATA_SOURCE=api), seule embarquée dans un build de production. */
const source: DataSource = {
  demo: false,
  demoAccounts: [],
  auth: authApi,
  me: meApi,
  dashboard: dashboardApi,
  users: usersApi,
  content: contentApi,
  feedback: feedbackApi,
  billing: billingApi,
  support: supportApi,
  campaigns: campaignsApi,
  settings: settingsApi,
  team: teamApi,
  approvals: approvalsApi,
  audit: auditApi,
};

export default source;
