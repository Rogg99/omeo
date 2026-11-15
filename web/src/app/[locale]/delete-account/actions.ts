"use server";

import { z } from "zod";

import type { FormState } from "@/lib/form-state";
import source from "@/server/data/source";
import { formValues, invalidState, missingCaptcha, problemState, rateLimited } from "@/server/forms";
import { requestContext } from "@/server/request";

const requestSchema = z.object({ email: z.email().trim().max(254), captcha: z.string().max(4096).optional() });
const confirmSchema = z.object({ token: z.string().trim().min(16).max(512) });

type Sent = { email: string; demoToken?: string };

/**
 * Étape 1 : envoie le lien de confirmation. La réponse est la même que le compte existe ou non
 * (aucune fuite sur l'existence d'un compte).
 */
export async function requestDeletion(_previous: FormState<Sent>, formData: FormData): Promise<FormState<Sent>> {
  const ctx = await requestContext();
  const parsed = requestSchema.safeParse(formValues(formData));
  if (!parsed.success) return invalidState(parsed.error);
  const blocked = (await rateLimited("deletion", ctx)) ?? (await missingCaptcha(parsed.data.captcha));
  if (blocked) return blocked;
  const result = await source.accountDeletion.request(parsed.data.email, parsed.data.captcha ?? "", ctx);
  if (!result.ok) return problemState(result.problem);
  // Mode démo : le lien « reçu par email » est proposé directement sur la page.
  return { status: "success", data: { email: parsed.data.email, demoToken: source.demo?.lastDeletionToken() } };
}

/** Étape 2 : confirmation explicite (bouton) depuis le lien reçu, jamais au simple chargement de la page. */
export async function confirmDeletion(_previous: FormState, formData: FormData): Promise<FormState> {
  const ctx = await requestContext();
  const parsed = confirmSchema.safeParse(formValues(formData));
  if (!parsed.success) return invalidState(parsed.error);
  const blocked = await rateLimited("deletion-confirm", ctx);
  if (blocked) return blocked;
  const result = await source.accountDeletion.confirm(parsed.data.token, ctx);
  return result.ok ? { status: "success", data: null } : problemState(result.problem);
}
