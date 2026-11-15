"use server";

import { z } from "zod";

import type { FormState } from "@/lib/form-state";
import source from "@/server/data/source";
import { formValues, invalidState, missingCaptcha, problemState, rateLimited } from "@/server/forms";
import { requestContext } from "@/server/request";

import { CONTACT_CATEGORIES, MESSAGE_MAX } from "./schema";

const contactSchema = z.object({
  name: z.string().trim().min(1).max(120),
  email: z.email().trim().max(254),
  category: z.enum(CONTACT_CATEGORIES),
  subject: z.string().trim().min(3).max(150),
  message: z.string().trim().min(10).max(MESSAGE_MAX),
  consent: z.literal("on"),
  captcha: z.string().max(4096).optional(),
  idempotency_key: z.uuid(),
});

/** Crée une demande de support dans l'admin (POST /support/tickets). */
export async function sendContact(_previous: FormState<{ number: string }>, formData: FormData): Promise<FormState<{ number: string }>> {
  const ctx = await requestContext();
  const parsed = contactSchema.safeParse(formValues(formData));
  if (!parsed.success) return invalidState(parsed.error);
  const blocked = (await rateLimited("contact", ctx)) ?? (await missingCaptcha(parsed.data.captcha));
  if (blocked) return blocked;

  const { name, email, category, subject, message, captcha, idempotency_key } = parsed.data;
  const input = { name, email, category, subject, message, ...(captcha ? { captcha } : {}) };
  const result = await source.support.createTicket(input, idempotency_key, ctx);
  return result.ok ? { status: "success", data: { number: result.data.number } } : problemState(result.problem);
}
