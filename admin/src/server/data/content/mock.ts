import "server-only";

import { randomUUID } from "node:crypto";

import { CONTENT_TYPES, NEXT_STATUSES } from "@/lib/content-types";
import { LOCALES } from "@/lib/locales";
import { audit, matches, order, paginate, problem, requestApproval, run, type Actor } from "@/server/mock/runtime";
import { store, type ContentState } from "@/server/mock/state";
import type { I18nText, Locale } from "@/server/data/types";
import { adminOrigin } from "@/server/env";

import type { ContentItem, ContentRepository, ContentRow, ContentType } from ".";

/**
 * Contenus simulés. Les valeurs « calculées par l'API » (traductions manquantes, nutriments d'une
 * recette ou d'un plat) sont dérivées ici des données : calcul toléré dans le dossier mock pour que
 * la démo réagisse aux modifications.
 */

const isI18n = (v: unknown): v is I18nText & { fr: string } =>
  typeof v === "object" && v !== null && !Array.isArray(v) && typeof (v as Record<string, unknown>).fr === "string";

/** Tous les textes multilingues d'un contenu, à n'importe quelle profondeur. */
function i18nFields(value: unknown, out: I18nText[] = []): I18nText[] {
  if (isI18n(value)) out.push(value);
  else if (Array.isArray(value)) value.forEach((v) => i18nFields(v, out));
  else if (typeof value === "object" && value !== null) Object.values(value).forEach((v) => i18nFields(v, out));
  return out;
}

function missingLocales(data: Record<string, unknown>): Locale[] {
  const fields = i18nFields(data);
  const active = store().settings.app?.active_locales ?? [...LOCALES];
  return active.filter((l) => fields.some((f) => !f[l]?.trim()));
}

function titleOf(c: ContentState): string {
  const d = c.data;
  for (const key of ["name", "common_name", "title", "question"]) {
    const v = d[key];
    if (isI18n(v)) return v.fr;
  }
  if (typeof d.action === "string") return d.action;
  if (typeof d.kind === "string") return d.kind;
  return c.id;
}

const staffName = (id: string) => store().staff.find((s) => s.id === id)?.name ?? null;

function row(c: ContentState): ContentRow {
  return {
    id: c.id,
    type: c.type,
    title: titleOf(c),
    status: c.status,
    missing_locales: missingLocales(c.data),
    thumbnail: c.thumbnail ? { url: c.thumbnail, width: 1200, height: 900 } : null,
    updated_at: c.updatedAt,
    updated_by: staffName(c.authorId),
  };
}

type Line = { food_id?: unknown; grams?: unknown };

/** Nutriments d'une liste d'ingrédients (valeurs des aliments pour 100 g), divisés par `portions`. */
function nutrients(lines: Line[], portions: number) {
  const foods = new Map(store().content.filter((c) => c.type === "foods").map((f) => [f.id, f.data]));
  const keys = ["kcal", "protein_g", "carbs_g", "fat_g", "fiber_g", "salt_g"] as const;
  const totals = Object.fromEntries(keys.map((k) => [k, 0])) as Record<(typeof keys)[number], number>;
  for (const line of lines) {
    const food = foods.get(String(line.food_id));
    const grams = Number(line.grams) || 0;
    if (!food) continue;
    for (const k of keys) totals[k] += ((Number(food[k]) || 0) * grams) / 100;
  }
  const round = (n: number, digits: number) => Math.round((n / Math.max(1, portions)) * 10 ** digits) / 10 ** digits;
  return { kcal: round(totals.kcal, 0), protein_g: round(totals.protein_g, 1), carbs_g: round(totals.carbs_g, 1), fat_g: round(totals.fat_g, 1), fiber_g: round(totals.fiber_g, 1), salt_g: round(totals.salt_g, 2) };
}

function computed(c: ContentState): Record<string, unknown> | undefined {
  if (c.type === "recipes") {
    const servings = Number(c.data.servings) || 1;
    return { per_serving: nutrients((c.data.ingredients as Line[]) ?? [], servings), servings };
  }
  if (c.type === "dishes") return { per_portion: nutrients((c.data.components as Line[]) ?? [], 1) };
  if (c.type === "workouts") {
    const steps = (c.data.steps as { duration_s?: number; reps?: number; rest_s?: number }[]) ?? [];
    const seconds = steps.reduce((sum, s) => sum + (s.duration_s ?? (s.reps ?? 0) * 3) + (s.rest_s ?? 0), 0);
    return { duration_min: Math.round(seconds / 60) };
  }
  return undefined;
}

function item(c: ContentState): ContentItem {
  return { ...row(c), version: c.version, data: c.data, computed: computed(c) };
}

const find = (type: ContentType, id: string) => store().content.find((c) => c.type === type && c.id === id);

function snapshot(c: ContentState, actor: Actor) {
  const list = store().revisions.get(c.id) ?? [];
  list.unshift({ id: randomUUID(), author: actor.staff.name ?? actor.staff.email, created_at: c.updatedAt, snapshot: { version: c.version, status: c.status, data: structuredClone(c.data) } });
  store().revisions.set(c.id, list);
}

function publish(c: ContentState, actor: Actor) {
  const before = c.status;
  c.status = "published";
  c.everPublished = true;
  c.version += 1;
  c.updatedAt = new Date().toISOString();
  snapshot(c, actor);
  audit(actor.staff, "content.publish", { type: c.type, id: c.id }, { status: before }, { status: "published", version: c.version });
}

const isType = (t: string): t is ContentType => (CONTENT_TYPES as readonly string[]).includes(t);

export const contentMock: ContentRepository = {
  list: (type, query, ctx) =>
    run(ctx, { permission: "content.view" }, () => {
      if (!isType(type)) return problem(404, "not_found");
      const rows = store()
        .content.filter((c) => c.type === type)
        .map(row)
        .filter((r) => matches(query.q, r.title))
        .filter((r) => !query.status || r.status === query.status)
        .filter((r) => !query.missing_locale || r.missing_locales.includes(query.missing_locale));
      return paginate(order(rows, query.ordering, "-updated_at"), query);
    }),

  get: (type, id, ctx) =>
    run(ctx, { permission: "content.view" }, () => {
      const c = find(type, id);
      return c ? item(c) : problem(404, "not_found");
    }),

  create: (type, payload, ctx) =>
    run(ctx, { permission: "content.edit" }, (actor) => {
      if (!isType(type)) return problem(404, "not_found");
      const c: ContentState = {
        id: randomUUID(),
        type,
        status: "draft",
        authorId: actor.staff.id,
        updatedAt: new Date().toISOString(),
        everPublished: false,
        data: payload.data as Record<string, unknown>,
        version: 1,
      };
      store().content.unshift(c);
      snapshot(c, actor);
      audit(actor.staff, "content.create", { type, id: c.id }, null, { title: titleOf(c) });
      return item(c);
    }),

  update: (type, id, payload, ctx) =>
    run(ctx, { permission: "content.edit" }, (actor) => {
      const c = find(type, id);
      if (!c) return problem(404, "not_found");
      if (payload.version !== c.version) {
        return problem(409, "conflict", { detail: "version_mismatch", meta: { current_version: c.version, current: item(c) } });
      }
      const before = { version: c.version };
      c.data = payload.data as Record<string, unknown>;
      c.version += 1;
      c.authorId = actor.staff.id;
      c.updatedAt = new Date().toISOString();
      snapshot(c, actor);
      audit(actor.staff, "content.edit", { type, id }, before, { version: c.version });
      return item(c);
    }),

  remove: (type, id, ctx) =>
    run(ctx, { permission: "content.edit" }, (actor) => {
      const c = find(type, id);
      if (!c) return problem(404, "not_found");
      if (c.everPublished || c.status !== "draft") return problem(409, "conflict", { detail: "archive_instead" });
      store().content = store().content.filter((x) => x.id !== id);
      audit(actor.staff, "content.delete", { type, id }, { title: titleOf(c) }, null);
      return null;
    }),

  transition: (type, id, input, ctx) =>
    run(ctx, { permission: "content.edit" }, (actor) => {
      const c = find(type, id);
      if (!c) return problem(404, "not_found");
      if (!NEXT_STATUSES[c.status].includes(input.to)) return problem(409, "conflict", { detail: "invalid_transition" });

      if (input.to === "published") {
        const own = c.authorId === actor.staff.id;
        if (own) {
          // Correction mineure de son propre contenu : uniquement avec content.publish_own et un motif.
          if (!actor.permissions.includes("content.publish_own")) return problem(403, "self_approval_forbidden");
          if (!input.comment?.trim()) {
            return problem(422, "validation_error", { errors: { comment: [{ code: "required", message: "Motif obligatoire" }] } });
          }
          publish(c, actor);
          return { status: "applied" as const, data: item(c) };
        }
        if (!actor.permissions.includes("content.publish")) return problem(403, "forbidden_role", { meta: { permission: "content.publish" } });
        publish(c, actor);
        return { status: "applied" as const, data: item(c) };
      }

      const before = c.status;
      c.status = input.to;
      c.updatedAt = new Date().toISOString();
      audit(actor.staff, `content.${input.to}`, { type, id }, { status: before }, { status: input.to, comment: input.comment ?? null });

      // Passage en relecture : la publication devient une demande à valider par une autre personne.
      if (input.to === "review") {
        const approval = requestApproval(
          actor.staff,
          {
            kind: "content_publish",
            domain: "content",
            summary: `Publier « ${titleOf(c)} »`,
            target_type: type,
            target_id: id,
            diff: { status: { before: "review", after: "published" } },
            reason: input.comment ?? null,
          },
          () => publish(c, actor),
        );
        if ("code" in approval) return approval;
        return { status: "pending" as const, approval };
      }
      return { status: "applied" as const, data: item(c) };
    }),

  revisions: (type, id, ctx) =>
    run(ctx, { permission: "content.view" }, () => (find(type, id) ? (store().revisions.get(id) ?? []) : problem(404, "not_found"))),

  translate: (type, id, locales, ctx) =>
    run(ctx, { permission: "content.translate" }, () => {
      const c = find(type, id);
      if (!c) return problem(404, "not_found");
      // Proposition simulée : le texte français, préfixé de la langue. À relire avant d'enregistrer.
      const out: Record<string, I18nText> = {};
      for (const [key, value] of Object.entries(c.data)) {
        if (!isI18n(value)) continue;
        const proposal: I18nText = {};
        for (const l of locales) if (!value[l]?.trim()) proposal[l] = `[${l.toUpperCase()}] ${value.fr}`;
        if (Object.keys(proposal).length) out[key] = proposal;
      }
      return out;
    }),

  coverage: (ctx) =>
    run(ctx, { permission: "content.view" }, () => {
      const active = store().settings.app?.active_locales ?? [...LOCALES];
      return CONTENT_TYPES.flatMap((type) => {
        const items = store().content.filter((c) => c.type === type);
        return active.map((locale) => {
          const missing = items.filter((c) => missingLocales(c.data).includes(locale)).length;
          return { type, locale, total: items.length, missing, percent: items.length ? (items.length - missing) / items.length : 1 };
        });
      });
    }),

  createUpload: (input, ctx) =>
    run(ctx, { permission: "content.edit" }, () => {
      const id = randomUUID();
      return {
        id,
        upload_url: `${adminOrigin}/mock-upload/${id}`,
        method: "PUT" as const,
        headers: { "Content-Type": input.content_type },
        expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
      };
    }),
};
