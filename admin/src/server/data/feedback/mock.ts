import "server-only";

import { randomUUID } from "node:crypto";

import { FEEDBACK_STATS } from "@/server/mock/fixtures/feedback";
import { audit, paginate, problem, run } from "@/server/mock/runtime";
import { store } from "@/server/mock/state";

import type { FeedbackDetail, FeedbackRepository, FeedbackRow } from ".";

function row(f: FeedbackDetail): FeedbackRow {
  const { id, rating, reason, status, dish_label, confidence, locale, country, thumbnail, created_at } = f;
  return { id, rating, reason, status, dish_label, confidence, locale, country, thumbnail, created_at };
}

/** Ordre par défaut de l'API : les 👎 d'abord, puis les plus récents. */
const byDefault = (a: FeedbackRow, b: FeedbackRow) =>
  (a.rating === b.rating ? 0 : a.rating === "down" ? -1 : 1) || b.created_at.localeCompare(a.created_at);

const day = (iso: string) => iso.slice(0, 10);

export const feedbackMock: FeedbackRepository = {
  list: (query, ctx) =>
    run(ctx, { permission: "feedback.view" }, () => {
      const rows = store()
        .feedback.filter((f) => !query.rating || f.rating === query.rating)
        .filter((f) => !query.reason || f.reason === query.reason)
        .filter((f) => !query.status || f.status === query.status)
        .filter((f) => !query.locale || f.locale === query.locale)
        .filter((f) => query.max_confidence === undefined || (f.confidence ?? 0) <= query.max_confidence)
        .filter((f) => !query.from || day(f.created_at) >= query.from)
        .filter((f) => !query.to || day(f.created_at) <= query.to)
        .map(row)
        .sort(byDefault);
      return paginate(rows, query);
    }),

  get: (id, ctx) =>
    run(ctx, { permission: "feedback.view" }, () => store().feedback.find((f) => f.id === id) ?? problem(404, "not_found")),

  resolve: (id, input, ctx) =>
    run(ctx, { permission: "feedback.resolve" }, ({ staff }) => {
      const f = store().feedback.find((x) => x.id === id);
      if (!f) return problem(404, "not_found");
      if (input.action === "add_alias" && !input.alias?.trim()) {
        return problem(422, "validation_error", { errors: { alias: [{ code: "required", message: "Nom requis" }] } });
      }
      const before = { status: f.status };
      f.status = input.action === "ignore" ? "ignored" : "handled";
      f.handled_by = staff.name ?? staff.email;
      f.handled_action = input.action;
      let created: string | null = null;
      if (input.action === "create_dish" || input.action === "create_food") {
        created = randomUUID();
        const label = f.dish_label ?? "Nouveau plat";
        store().content.unshift({
          id: created,
          type: input.action === "create_dish" ? "dishes" : "foods",
          status: "draft",
          authorId: staff.id,
          updatedAt: new Date().toISOString(),
          everPublished: false,
          version: 1,
          data:
            input.action === "create_dish"
              ? { name: { fr: label }, aliases: [], country: f.country ?? "", standard_portion_g: 350, components: f.corrected_items?.map((i) => ({ food_id: i.food_id, grams: i.grams })) ?? [] }
              : { name: { fr: label }, aliases: [], category: "base", kcal: 0, protein_g: 0, carbs_g: 0, fat_g: 0 },
        });
      }
      if (input.action === "add_alias" && input.dish_id && input.alias) {
        const dish = store().content.find((c) => c.id === input.dish_id && c.type === "dishes");
        if (dish) dish.data.aliases = [...((dish.data.aliases as string[]) ?? []), input.alias.trim()];
      }
      audit(staff, `feedback.${input.action}`, { type: "feedback", id }, before, { status: f.status, note: input.note ?? null, created_content_id: created });
      return { status: f.status, created_content_id: created };
    }),

  stats: (_query, ctx) => run(ctx, { permission: "feedback.view" }, () => FEEDBACK_STATS),
};
