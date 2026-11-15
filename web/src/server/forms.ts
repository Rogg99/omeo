import "server-only";

import { getTranslations } from "next-intl/server";
import type { z } from "zod";

import type { FormState } from "@/lib/form-state";
import source from "@/server/data/source";
import type { Problem, RequestContext } from "@/server/data/types";
import { hit, RATE_LIMITS, type RateLimitRule } from "@/server/rate-limit";
import { rateKey } from "@/server/request";

/** Codes d'erreur traduits dans le catalogue (errors.*). Tout autre code affiche server_error. */
const KNOWN_CODES = new Set([
  "validation_error",
  "invalid_credentials",
  "token_expired",
  "not_authenticated",
  "email_not_verified",
  "rate_limited",
  "server_error",
  "conflict",
  "not_found",
  "forbidden",
  "captcha_failed",
  "network_error",
]);

/** Message d'erreur d'après le `code` du problem+json (jamais d'après son texte). */
export async function errorMessage(code: string): Promise<string> {
  const t = await getTranslations("errors");
  return t(KNOWN_CODES.has(code) ? (code as "server_error") : "server_error");
}

export async function problemState(problem: Problem): Promise<FormState<never>> {
  return { status: "error", message: await errorMessage(problem.code), fields: Object.keys(problem.errors ?? {}) };
}

export async function invalidState(error: z.ZodError): Promise<FormState<never>> {
  const fields = [...new Set(error.issues.map((i) => String(i.path[0] ?? "")))].filter(Boolean);
  return { status: "error", message: await errorMessage("validation_error"), fields };
}

/** Limitation de débit d'un formulaire ; renvoie l'état d'erreur si la limite est atteinte. */
export async function rateLimited(scope: string, ctx: RequestContext, rule: RateLimitRule = RATE_LIMITS.form): Promise<FormState<never> | undefined> {
  return hit(rateKey(scope, ctx), rule).ok ? undefined : { status: "error", message: await errorMessage("rate_limited"), fields: [] };
}

/** Captcha exigé (sauf en mode mock) : vérifié par l'API, ici on refuse seulement un champ vide. */
export async function missingCaptcha(captcha: string | undefined): Promise<FormState<never> | undefined> {
  return source.captchaRequired && !captcha ? { status: "error", message: await errorMessage("captcha_failed"), fields: ["captcha"] } : undefined;
}

export function formValues(formData: FormData): Record<string, string> {
  const values: Record<string, string> = {};
  for (const [key, value] of formData) if (typeof value === "string") values[key] = value;
  return values;
}
