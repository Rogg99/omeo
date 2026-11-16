import "server-only";

import { USER_ACTION_PERMISSION } from "@/lib/permissions";
import { MAX_TRIAL_EXTENSION_DAYS } from "@/server/mock/fixtures/users";
import { audit, matches, order, paginate, problem, run } from "@/server/mock/runtime";
import { store } from "@/server/mock/state";

import type { UserDetail, UserRow, UsersRepository } from ".";

/** Actions protégées par un step-up (voir x-access-note de adminUserAction). */
const STEP_UP_ACTIONS = new Set(["suspend", "reactivate", "grant_plus_days", "export_data", "delete_data"]);

function row(u: UserDetail): UserRow {
  const { id, email, name, country, locale, tier, status, platform, last_seen_at, created_at } = u;
  return { id, email, name, country, locale, tier, status, platform, last_seen_at, created_at };
}

const find = (id: string) => store().users.find((u) => u.id === id);

export const usersMock: UsersRepository = {
  list: (query, ctx) =>
    run(ctx, { permission: "users.view" }, () => {
      const rows = store()
        .users.filter((u) => matches(query.q, u.email, u.name, u.id))
        .filter((u) => !query.plan || u.tier === query.plan)
        .filter((u) => !query.status || u.status === query.status)
        .filter((u) => !query.country || u.country === query.country)
        .map(row);
      return paginate(order(rows, query.ordering, "-created_at"), query);
    }),

  get: (id, ctx) => run(ctx, { permission: "users.view" }, () => find(id) ?? problem(404, "not_found")),

  revealHealth: (id, reason, ctx) =>
    run(ctx, { permission: "users.view_health", stepUp: true }, ({ staff }) => {
      if (reason.trim().length < 5) {
        return problem(422, "validation_error", { errors: { reason: [{ code: "min_length", message: "5 caractères minimum" }] } });
      }
      const user = find(id);
      if (!user) return problem(404, "not_found");
      audit(staff, "users.view_health", { type: "user", id }, null, { reason });
      return store().health[id] ?? {};
    }),

  action: (id, input, ctx) =>
    run(
      ctx,
      { permission: USER_ACTION_PERMISSION[input.action], stepUp: STEP_UP_ACTIONS.has(input.action) },
      ({ staff }) => {
        const user = find(id);
        if (!user) return problem(404, "not_found");
        const before = { status: user.status, tier: user.tier, trial_days_left: user.subscription?.trial_days_left ?? null };
        switch (input.action) {
          case "suspend":
            if (user.status === "suspended") return problem(409, "conflict");
            user.status = "suspended";
            break;
          case "reactivate":
            if (user.status !== "suspended") return problem(409, "conflict");
            user.status = "active";
            break;
          case "extend_trial": {
            const days = input.days ?? 0;
            if (user.tier !== "trial" || days < 1 || days > MAX_TRIAL_EXTENSION_DAYS) {
              return problem(422, "validation_error", {
                errors: { days: [{ code: "max", message: `${MAX_TRIAL_EXTENSION_DAYS} jours au maximum` }] },
              });
            }
            if (user.subscription) user.subscription.trial_days_left = (user.subscription.trial_days_left ?? 0) + days;
            break;
          }
          case "grant_plus_days": {
            const days = input.days ?? 0;
            if (days < 1) return problem(422, "validation_error");
            user.tier = "plus";
            if (user.subscription) user.subscription.granted_days_left = (user.subscription.granted_days_left ?? 0) + days;
            break;
          }
          case "reset_quota":
            for (const q of user.subscription?.quotas ?? []) {
              if (!input.feature || q.feature === input.feature) {
                q.used = 0;
                q.remaining = q.limit;
              }
            }
            break;
          case "delete_data":
            user.status = "deletion_pending";
            break;
          case "resend_verification":
          case "send_password_reset":
          case "export_data":
            break;
        }
        audit(staff, `users.${input.action}`, { type: "user", id }, before, {
          status: user.status,
          tier: user.tier,
          days: input.days ?? null,
          reason: input.reason,
        });
        return user;
      },
    ),
};
