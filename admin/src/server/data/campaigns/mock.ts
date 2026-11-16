import "server-only";

import { randomUUID } from "node:crypto";

import { audit, fourEyesEnabled, paginate, problem, requestApproval, run } from "@/server/mock/runtime";
import { store } from "@/server/mock/state";

import type { Campaign, CampaignsRepository, Segment } from ".";

/**
 * Estimation simulée de l'audience : base de 64 210 comptes, part avec consentement marketing,
 * réduite par chaque critère (calcul toléré dans le dossier mock, pour une estimation « en direct »).
 */
function estimate(segment: Segment): number {
  let n = 64_210 * 0.46;
  if (segment.locales?.length) n *= Math.min(1, segment.locales.length * 0.34);
  if (segment.countries?.length) n *= Math.min(1, segment.countries.length * 0.22);
  if (segment.tiers?.length) n *= Math.min(1, segment.tiers.length * 0.4);
  if (segment.goals?.length) n *= Math.min(1, segment.goals.length * 0.25);
  if (segment.inactive_days_min) n *= Math.max(0.05, 1 - segment.inactive_days_min / 60);
  return Math.round(n / 10) * 10;
}

const find = (id: string) => store().campaigns.find((c) => c.id === id);

export const campaignsMock: CampaignsRepository = {
  list: (query, ctx) =>
    run(ctx, { permission: "campaigns.view" }, () =>
      paginate([...store().campaigns].sort((a, b) => (b.created_at ?? "").localeCompare(a.created_at ?? "")), query),
    ),

  get: (id, ctx) => run(ctx, { permission: "campaigns.view" }, () => find(id) ?? problem(404, "not_found")),

  create: (input, ctx) =>
    run(ctx, { permission: "campaigns.edit" }, ({ staff }) => {
      const campaign: Campaign = {
        ...input,
        id: randomUUID(),
        status: "draft",
        audience_count: estimate(input.segment),
        sent_count: 0,
        opened_count: 0,
        open_rate: null,
        created_by: staff.name ?? staff.email,
        created_at: new Date().toISOString(),
      };
      store().campaigns.unshift(campaign);
      audit(staff, "campaigns.create", { type: "campaign", id: campaign.id }, null, { title: input.title.fr ?? "" });
      return campaign;
    }),

  update: (id, input, ctx) =>
    run(ctx, { permission: "campaigns.edit" }, ({ staff }) => {
      const c = find(id);
      if (!c) return problem(404, "not_found");
      if (c.status !== "draft") return problem(409, "conflict", { detail: "not_a_draft" });
      Object.assign(c, input, { audience_count: estimate(input.segment) });
      audit(staff, "campaigns.edit", { type: "campaign", id }, null, { title: input.title.fr ?? "" });
      return c;
    }),

  audience: (segment, ctx) => run(ctx, { permission: "campaigns.edit" }, () => ({ count: estimate(segment) })),

  action: (id, action, ctx) =>
    run(
      ctx,
      { permission: action === "send_test" ? "campaigns.edit" : "campaigns.schedule", stepUp: action !== "send_test" },
      ({ staff }) => {
        const c = find(id);
        if (!c) return problem(404, "not_found");
        if (action === "send_test") {
          audit(staff, "campaigns.send_test", { type: "campaign", id }, null, { to: staff.email });
          return { status: "applied" as const, data: c };
        }
        const own = c.created_by === (staff.name ?? staff.email);
        if (action === "cancel") {
          if (own) return problem(403, "self_approval_forbidden");
          if (c.status !== "scheduled") return problem(409, "conflict");
          c.status = "canceled";
          audit(staff, "campaigns.cancel", { type: "campaign", id }, { status: "scheduled" }, { status: "canceled" });
          return { status: "applied" as const, data: c };
        }
        if (c.status !== "draft" || !c.scheduled_at) return problem(409, "conflict", { detail: "schedule_requires_draft_and_date" });
        const apply = () => {
          c.status = "scheduled";
          audit(staff, "campaigns.schedule", { type: "campaign", id }, { status: "draft" }, { status: "scheduled", scheduled_at: c.scheduled_at });
        };
        // Programmer la campagne d'une autre personne : c'est la seconde paire d'yeux, appliqué tout de suite.
        // Programmer la sienne : demande de validation par une autre personne (202).
        if (!own || !fourEyesEnabled("content")) {
          apply();
          return { status: "applied" as const, data: c };
        }
        const approval = requestApproval(
          staff,
          {
            kind: "campaign_schedule",
            domain: "content",
            summary: `Programmer « ${c.title.fr ?? ""} »`,
            target_type: "campaign",
            target_id: id,
            diff: { status: { before: "draft", after: "scheduled" }, scheduled_at: { before: null, after: c.scheduled_at } },
            reason: null,
          },
          apply,
        );
        return "code" in approval ? approval : { status: "pending" as const, approval };
      },
    ),
};
