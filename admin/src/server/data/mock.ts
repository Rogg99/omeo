import "server-only";

import { STAFF } from "@/server/mock/fixtures/staff";
import { MOCK_MARKER } from "@/server/mock/runtime";

import { approvalsMock } from "./approvals/mock";
import { auditMock } from "./audit/mock";
import { authMock } from "./auth/mock";
import { billingMock } from "./billing/mock";
import { campaignsMock } from "./campaigns/mock";
import { contentMock } from "./content/mock";
import type { DataSource } from "./contract";
import { dashboardMock } from "./dashboard/mock";
import { feedbackMock } from "./feedback/mock";
import { meMock } from "./me/mock";
import { settingsMock } from "./settings/mock";
import { supportMock } from "./support/mock";
import { teamMock } from "./team/mock";
import { usersMock } from "./users/mock";

/**
 * Couche de données simulée (DATA_SOURCE=mock) : mêmes formes et mêmes codes d'erreur que l'API.
 * Exclue des builds de production par l'alias `@/server/data/source` (next.config.ts) ; la CI
 * vérifie que le marqueur ci-dessous n'apparaît pas dans .next.
 */
const source: DataSource & { readonly marker: string } = {
  demo: true,
  demoAccounts: STAFF.map(({ email, name, roles }) => ({ email, name: name ?? email, roles })),
  marker: MOCK_MARKER,
  auth: authMock,
  me: meMock,
  dashboard: dashboardMock,
  users: usersMock,
  content: contentMock,
  feedback: feedbackMock,
  billing: billingMock,
  support: supportMock,
  campaigns: campaignsMock,
  settings: settingsMock,
  team: teamMock,
  approvals: approvalsMock,
  audit: auditMock,
};

export default source;
