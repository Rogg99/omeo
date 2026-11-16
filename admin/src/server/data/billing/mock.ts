import "server-only";

import { randomUUID } from "node:crypto";

import { audit, fourEyesEnabled, matches, paginate, problem, requestApproval, run } from "@/server/mock/runtime";
import { store } from "@/server/mock/state";

import type { BillingRepository, PaymentRow } from ".";

const usd = (cents: number) => ({ amount_cents: cents, currency: "USD" as const, formatted: `$${(cents / 100).toFixed(2)}` });

function doRefund(p: PaymentRow, cents: number) {
  p.refunded = usd((p.refunded?.amount_cents ?? 0) + cents);
  p.refundable = (p.refunded.amount_cents ?? 0) < p.amount.amount_cents;
  if (!p.refundable) p.status = "refunded";
}

export const billingMock: BillingRepository = {
  plans: (ctx) => run(ctx, { permission: "billing.view" }, () => store().plans),

  updatePlan: (code, plan, ctx) =>
    run(ctx, { permission: "billing.plans_edit" }, ({ staff }) => {
      const current = store().plans.find((p) => p.code === code);
      if (!current) return problem(404, "not_found");
      const next = { ...current, ...plan, code };
      const apply = () => {
        Object.assign(current, next);
        audit(staff, "billing.plans_edit", { type: "plan", id: code }, { price_cents: current.price_cents }, { price_cents: next.price_cents });
      };
      if (!fourEyesEnabled("finance")) {
        apply();
        return { status: "applied" as const, data: current };
      }
      const approval = requestApproval(
        staff,
        {
          kind: "plan_update",
          domain: "finance",
          summary: `Modifier l'offre ${code}`,
          target_type: "plan",
          target_id: code,
          diff: { before: current, after: next },
          reason: null,
        },
        apply,
      );
      return "code" in approval ? approval : { status: "pending" as const, approval };
    }),

  quotas: (ctx) => run(ctx, { permission: "billing.view" }, () => store().quotas),

  replaceQuotas: (rules, ctx) =>
    run(ctx, { permission: "billing.quotas_edit" }, ({ staff }) => {
      const before = store().quotas;
      const apply = () => {
        store().quotas = rules;
        audit(staff, "billing.quotas_edit", { type: "quotas", id: "all" }, { rules: before }, { rules });
      };
      if (!fourEyesEnabled("finance")) {
        apply();
        return { status: "applied" as const, data: rules };
      }
      const approval = requestApproval(
        staff,
        { kind: "quota_update", domain: "finance", summary: "Modifier les quotas", target_type: "quotas", target_id: "all", diff: { before, after: rules }, reason: null },
        apply,
      );
      return "code" in approval ? approval : { status: "pending" as const, approval };
    }),

  subscriptions: (query, ctx) =>
    run(ctx, { permission: "billing.view" }, () =>
      paginate(
        store()
          .subscriptions.filter((s) => !query.status || s.status === query.status)
          .filter((s) => !query.channel || s.channel === query.channel)
          .filter((s) => matches(query.q, s.user_email, s.id, s.user_id)),
        query,
      ),
    ),

  payments: (query, ctx) =>
    run(ctx, { permission: "billing.view" }, () =>
      paginate(
        store()
          .payments.filter((p) => !query.status || p.status === query.status)
          .filter((p) => !query.channel || p.channel === query.channel)
          .filter((p) => !query.from || p.paid_at.slice(0, 10) >= query.from)
          .filter((p) => !query.to || p.paid_at.slice(0, 10) <= query.to),
        query,
      ),
    ),

  refund: (id, input, ctx) =>
    run(ctx, { permission: "billing.refund", stepUp: true }, ({ staff }) => {
      const p = store().payments.find((x) => x.id === id);
      if (!p) return problem(404, "not_found");
      if (p.channel !== "web") return problem(409, "conflict", { detail: "store_refunds_are_handled_by_the_store" });
      if (!p.refundable) return problem(409, "conflict", { detail: "not_refundable" });
      const remaining = p.amount.amount_cents - (p.refunded?.amount_cents ?? 0);
      const cents = input.amount_cents ?? remaining;
      if (cents > remaining) {
        return problem(422, "validation_error", { errors: { amount_cents: [{ code: "max", message: "Supérieur au montant restant" }] } });
      }
      const full = cents === remaining;
      if (full && input.confirm?.trim().toLowerCase() !== p.user_email?.toLowerCase()) {
        return problem(422, "validation_error", { errors: { confirm: [{ code: "mismatch", message: "Email de confirmation incorrect" }] } });
      }
      const apply = () => {
        doRefund(p, cents);
        audit(staff, "billing.refund", { type: "payment", id }, { refunded: null }, { amount_cents: cents, reason: input.reason });
      };
      const threshold = (store().settings.billing?.refund_approval_threshold_usd ?? 50) * 100;
      if (cents > threshold && fourEyesEnabled("finance")) {
        const approval = requestApproval(
          staff,
          {
            kind: "refund",
            domain: "finance",
            summary: `Rembourser ${usd(cents).formatted} à ${p.user_email}`,
            target_type: "payment",
            target_id: id,
            diff: { refunded: { before: p.refunded?.formatted ?? null, after: usd(cents).formatted } },
            reason: input.reason,
          },
          apply,
        );
        return "code" in approval ? approval : { status: "pending" as const, approval };
      }
      apply();
      return { status: "applied" as const, data: p };
    }),

  promoCodes: (query, ctx) => run(ctx, { permission: "billing.view" }, () => paginate(store().promos, query)),

  createPromo: (input, ctx) =>
    run(ctx, { permission: "billing.promo_manage" }, ({ staff }) => {
      if (store().promos.some((p) => p.code === input.code)) {
        return problem(422, "validation_error", { errors: { code: [{ code: "unique", message: "Code déjà utilisé" }] } });
      }
      const promo = { ...input, id: randomUUID(), redeemed_count: 0, active: input.active ?? true };
      store().promos.unshift(promo);
      audit(staff, "billing.promo_create", { type: "promo", id: promo.id }, null, { code: promo.code });
      return promo;
    }),

  updatePromo: (id, input, ctx) =>
    run(ctx, { permission: "billing.promo_manage" }, ({ staff }) => {
      const promo = store().promos.find((p) => p.id === id);
      if (!promo) return problem(404, "not_found");
      const before = { ...promo };
      Object.assign(promo, input, { id, redeemed_count: promo.redeemed_count });
      audit(staff, "billing.promo_edit", { type: "promo", id }, before, { ...promo });
      return promo;
    }),
};
