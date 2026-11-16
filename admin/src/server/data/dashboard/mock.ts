import "server-only";

import { DASHBOARD } from "@/server/mock/fixtures/misc";
import { run } from "@/server/mock/runtime";
import { store } from "@/server/mock/state";

import type { DashboardRepository } from ".";

/**
 * Tableau de bord simulé. Comme l'API, les blocs finance et support valent `null` sans la permission
 * correspondante. Les filtres (période, pays, langue, plateforme) appliquent un facteur fixe à la
 * fixture pour rendre la démo vivante (calcul toléré dans le dossier mock uniquement).
 */
const FILTER_FACTOR = { country: 0.42, locale: 0.68, platform: 0.55 } as const;

export const dashboardMock: DashboardRepository = {
  get: (query, ctx) =>
    run(ctx, { permission: "dashboard.product" }, ({ permissions }) => {
      const factor =
        (query.country ? FILTER_FACTOR.country : 1) *
        (query.locale ? FILTER_FACTOR.locale : 1) *
        (query.platform ? FILTER_FACTOR.platform : 1);
      const scale = (n: number) => Math.round(n * factor);
      const series = (s: typeof DASHBOARD.signups) =>
        s && { ...s, total: scale(s.total ?? 0), series: s.series?.map((p) => ({ ...p, value: scale(p.value ?? 0) })) };
      const finance = permissions.includes("dashboard.finance");
      const support = permissions.includes("dashboard.support");
      const pending = store().tickets.filter((t) => t.status === "new" || t.status === "open").length;
      return {
        ...DASHBOARD,
        signups: series(DASHBOARD.signups),
        analyses: series(DASHBOARD.analyses),
        active_users: DASHBOARD.active_users && {
          dau: scale(DASHBOARD.active_users.dau ?? 0),
          wau: scale(DASHBOARD.active_users.wau ?? 0),
          mau: scale(DASHBOARD.active_users.mau ?? 0),
        },
        trial_to_plus_rate: finance ? DASHBOARD.trial_to_plus_rate : null,
        revenue_by_channel: finance ? DASHBOARD.revenue_by_channel : null,
        mrr: finance ? DASHBOARD.mrr : null,
        ai_cost: finance ? DASHBOARD.ai_cost : null,
        support_pending: support ? pending : null,
      };
    }),
};
