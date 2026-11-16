"use server";

import { z } from "zod";

import type { ActionResult } from "@/lib/action-result";
import type { components } from "@/lib/api/schema";
import { CONTENT_STATUSES, CONTENT_TYPES } from "@/lib/content-types";
import { LOCALES } from "@/lib/locales";
import { staffAction, staffAppliedAction } from "@/server/action";
import source from "@/server/data/source";

type S = components["schemas"];

const type = z.enum(CONTENT_TYPES);
const id = z.uuid();
/** Corps typé selon le type : vérifié par l'API (schémas Admin* du contrat). */
const data = z.record(z.string(), z.unknown());

export async function saveContent(
  raw: unknown,
): Promise<ActionResult<S["AdminContentItem"]>> {
  return staffAction(
    raw,
    z.object({ type, id: id.optional(), version: z.number().int().min(1).optional(), data }),
    (input, ctx) => {
      const payload = { data: input.data, ...(input.version ? { version: input.version } : {}) } as S["AdminContentPayload"];
      return input.id
        ? source.content.update(input.type, input.id, payload, ctx)
        : source.content.create(input.type, payload, ctx);
    },
  );
}

export async function transitionContent(raw: unknown): Promise<ActionResult<S["AdminContentItem"]>> {
  return staffAppliedAction(
    raw,
    z.object({ type, id, to: z.enum(CONTENT_STATUSES), comment: z.string().trim().max(500).optional() }),
    ({ type: t, id: contentId, ...input }, ctx) => source.content.transition(t, contentId, input, ctx),
  );
}

export async function deleteContent(raw: unknown): Promise<ActionResult<null>> {
  return staffAction(raw, z.object({ type, id }), (input, ctx) => source.content.remove(input.type, input.id, ctx), {
    refreshPage: false,
  });
}

export async function translateContent(raw: unknown): Promise<ActionResult<Record<string, S["I18nText"]>>> {
  return staffAction(
    raw,
    z.object({ type, id, locales: z.array(z.enum(LOCALES)).min(1) }),
    (input, ctx) => source.content.translate(input.type, input.id, input.locales, ctx),
    { refreshPage: false },
  );
}

export async function revisionsOf(raw: unknown) {
  return staffAction(raw, z.object({ type, id }), (input, ctx) => source.content.revisions(input.type, input.id, ctx), {
    refreshPage: false,
  });
}

/** Recherche de contenus à relier (aliments d'une recette, recettes d'un programme…). */
export async function searchContent(raw: unknown): Promise<ActionResult<{ id: string; title: string }[]>> {
  return staffAction(
    raw,
    z.object({ type, q: z.string().trim().max(80).optional(), ids: z.array(id).max(50).optional() }),
    async (input, ctx) => {
      const r = await source.content.list(input.type, { q: input.q, page_size: 50 }, ctx);
      if (!r.ok) return r;
      const rows = r.data.results.filter((c) => !input.ids || input.ids.includes(c.id));
      return { ok: true, data: rows.map((c) => ({ id: c.id, title: c.title })) };
    },
    { refreshPage: false },
  );
}

/** URL présignée de téléversement direct (le fichier ne transite pas par le serveur de l'admin). */
export async function createUpload(raw: unknown): Promise<ActionResult<S["UploadTicket"]>> {
  return staffAction(
    raw,
    z.object({
      kind: z.enum(["image", "video", "subtitles"]),
      content_type: z.string().regex(/^(image\/(jpeg|png|webp)|video\/(mp4|quicktime|webm)|text\/vtt)$/),
      size: z.number().int().min(1).max(524_288_000),
    }),
    (input, ctx) => source.content.createUpload(input, ctx),
    { refreshPage: false },
  );
}
