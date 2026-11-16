"use server";

import { z } from "zod";

import type { ActionResult } from "@/lib/action-result";
import type { components } from "@/lib/api/schema";
import { staffAction } from "@/server/action";
import source from "@/server/data/source";

const id = z.uuid();
const reason = z.string().trim().min(3).max(500);

/** Révèle les données de santé : step-up et motif (5 à 200 caractères), consultation journalisée par l'API. */
export async function revealHealth(raw: unknown): Promise<ActionResult<components["schemas"]["AdminUserHealth"]>> {
  return staffAction(
    raw,
    z.object({ id, reason: z.string().trim().min(5).max(200) }),
    (input, ctx) => source.users.revealHealth(input.id, input.reason, ctx),
    { refreshPage: false },
  );
}

const actionSchema = z.object({
  id,
  action: z.enum([
    "suspend",
    "reactivate",
    "resend_verification",
    "send_password_reset",
    "extend_trial",
    "grant_plus_days",
    "reset_quota",
    "export_data",
    "delete_data",
  ]),
  reason,
  days: z.number().int().min(1).max(365).optional(),
  feature: z.enum(["photo_analysis", "text_analysis"]).optional(),
});

/** Action sur un compte (motif obligatoire, journalisée ; step-up selon l'action, imposé par l'API). */
export async function userAction(raw: unknown): Promise<ActionResult<components["schemas"]["AdminUserDetail"]>> {
  return staffAction(raw, actionSchema, ({ id: userId, ...input }, ctx) => source.users.action(userId, input, ctx));
}
