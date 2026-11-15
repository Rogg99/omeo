"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { getLocale, getTranslations } from "next-intl/server";
import { z } from "zod";

import { DEFAULT_LOCALE, isLocale, type Locale } from "@/i18n/routing";
import type { FormState } from "@/lib/form-state";
import source from "@/server/data/source";
import type { Problem } from "@/server/data/types";
import { siteOrigin } from "@/server/env";
import { errorMessage, formValues, invalidState, problemState, rateLimited } from "@/server/forms";
import { RATE_LIMITS } from "@/server/rate-limit";
import { requestContext } from "@/server/request";
import { clearSession, ensureSession, writeSession } from "@/server/session";
import { safeNextPath } from "@/server/session-cookies";
import { finishSocial, loginPath } from "@/server/subscription";

async function currentLocale(): Promise<Locale> {
  const locale = await getLocale();
  return isLocale(locale) ? locale : DEFAULT_LOCALE;
}

const loginSchema = z.object({
  email: z.email().trim().max(254),
  password: z.string().min(1).max(256),
  next: z.string().max(512).optional(),
});

/** Connexion par email et mot de passe (le même compte que dans l'app). */
export async function login(_previous: FormState, formData: FormData): Promise<FormState> {
  const ctx = await requestContext();
  const parsed = loginSchema.safeParse(formValues(formData));
  if (!parsed.success) return invalidState(parsed.error);
  const blocked = await rateLimited("login", ctx, RATE_LIMITS.login);
  if (blocked) return blocked;

  const result = await source.auth.login(parsed.data.email, parsed.data.password, ctx);
  if (!result.ok) {
    // Identifiants refusés : les deux champs sont signalés, sans indiquer si le compte existe.
    if (result.problem.code === "invalid_credentials") {
      return { status: "error", message: await errorMessage("invalid_credentials"), fields: ["email", "password"] };
    }
    return problemState(result.problem);
  }
  writeSession(await cookies(), result.data.tokens, result.data.me.email);
  redirect(safeNextPath(parsed.data.next, `/${ctx.locale}/subscription`));
}

export async function logout(): Promise<void> {
  const locale = await currentLocale();
  const ctx = await requestContext(locale);
  const session = await ensureSession(ctx);
  if (session) await source.auth.logout(session);
  clearSession(await cookies());
  redirect(loginPath(locale));
}

const checkoutSchema = z.object({
  plan_code: z.enum(["plus_monthly", "plus_annual"]),
  promo_code: z.string().trim().max(40).optional(),
  idempotency_key: z.uuid(),
});

/** Message d'un refus de paiement, d'après le code du contrat. */
async function checkoutError(problem: Problem): Promise<FormState> {
  const t = await getTranslations("web.subscription");
  if (problem.code === "email_not_verified") return { status: "error", message: t("email_not_verified"), fields: [] };
  if (problem.code === "conflict") return { status: "error", message: t("store_conflict"), fields: [] };
  if (problem.code === "validation_error" && problem.errors?.promo_code) return { status: "error", message: t("promo_invalid"), fields: ["promo_code"] };
  return problemState(problem);
}

/** Crée la session de paiement de l'agrégateur puis y redirige (aucune donnée de carte sur le site). */
export async function startCheckout(_previous: FormState, formData: FormData): Promise<FormState> {
  const locale = await currentLocale();
  const session = await ensureSession(await requestContext(locale));
  if (!session) redirect(loginPath(locale, "expired"));
  const parsed = checkoutSchema.safeParse(formValues(formData));
  if (!parsed.success) return invalidState(parsed.error);

  const base = `${siteOrigin}/${locale}/subscription`;
  const { plan_code, promo_code, idempotency_key } = parsed.data;
  const result = await source.billing.checkout(
    { plan_code, ...(promo_code ? { promo_code } : {}), success_url: `${base}/success`, cancel_url: `${base}/failed` },
    idempotency_key,
    session,
  );
  if (!result.ok) {
    if (result.problem.status === 401) redirect(loginPath(locale, "expired"));
    return checkoutError(result.problem);
  }
  redirect(result.data.checkout_url);
}

/** Portail de l'agrégateur : carte, changement d'offre, résiliation. */
export async function openPortal(): Promise<FormState> {
  const locale = await currentLocale();
  const session = await ensureSession(await requestContext(locale));
  if (!session) redirect(loginPath(locale, "expired"));
  const result = await source.billing.portal(`${siteOrigin}/${locale}/subscription/manage`, session);
  if (!result.ok) return { status: "error", message: await errorMessage(result.problem.code), fields: [] };
  redirect(result.data.url);
}

/* Simulateurs du mode démo : sans effet (404) avec l'API réelle. */

const outcomeSchema = z.object({ session: z.uuid(), outcome: z.enum(["success", "failure", "abandon"]) });

export async function mockCompleteCheckout(formData: FormData): Promise<void> {
  const parsed = outcomeSchema.safeParse(formValues(formData));
  const target = parsed.success ? source.demo?.completeCheckout(parsed.data.session, parsed.data.outcome) : undefined;
  redirect(target ?? `/${await currentLocale()}/subscription/plan`);
}

export async function mockSetAutoRenew(formData: FormData): Promise<void> {
  const locale = await currentLocale();
  const session = await ensureSession(await requestContext(locale));
  if (session && source.demo) source.demo.setAutoRenew(session.accessToken, formData.get("auto_renew") === "true");
  redirect(`/${locale}/subscription/mock-portal?return=${encodeURIComponent(String(formData.get("return") ?? ""))}`);
}

const socialSchema = z.object({ provider: z.enum(["google", "apple"]), email: z.string().max(254).optional() });

export async function mockSocialLogin(formData: FormData): Promise<void> {
  const locale = await currentLocale();
  const parsed = socialSchema.safeParse(formValues(formData));
  if (!source.demo || !parsed.success) redirect(loginPath(locale));
  const ctx = await requestContext(locale);
  const idToken = source.demo.socialIdToken(parsed.data.email || null);
  const outcome = await finishSocial(await source.auth.social(parsed.data.provider, idToken, undefined, ctx), ctx);
  redirect(outcome === "ok" ? `/${locale}/subscription` : `${loginPath(locale)}?error=${outcome}`);
}
