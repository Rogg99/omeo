import "server-only";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import type { Locale } from "@/i18n/routing";
import source from "@/server/data/source";
import type { AuthedContext, AuthResult, Problem, Result, SubscriptionState } from "@/server/data/types";
import { env } from "@/server/env";
import { requestContext } from "@/server/request";
import { readSession, writeSession } from "@/server/session";
import { SESSION_COOKIES } from "@/server/session-cookies";

/** Étape de la page Abonnement correspondant à l'état renvoyé par l'API (champ can_manage). */
export function stepFor(state: Pick<SubscriptionState, "can_manage">): "store" | "manage" | "plan" {
  if (state.can_manage === "store") return "store";
  if (state.can_manage === "web") return "manage";
  return "plan";
}

export function loginPath(locale: Locale, reason?: "expired"): string {
  return `/${locale}/subscription/login${reason ? `?${reason}=1` : ""}`;
}

/** Session requise : sinon retour à la connexion (session expirée si des cookies existaient). */
export async function requireSession(locale: Locale): Promise<AuthedContext> {
  const ctx = await requestContext(locale);
  const session = await readSession(ctx);
  if (session) return session;
  const hadSession = (await cookies()).has(SESSION_COOKIES.refresh);
  redirect(loginPath(locale, hadSession ? "expired" : undefined));
}

export type SubscriptionPage = { session: AuthedContext; state: SubscriptionState } | { session: AuthedContext; problem: Problem };

/** État d'abonnement de la session ; une session refusée par l'API renvoie à la connexion. */
export async function loadSubscription(locale: Locale): Promise<SubscriptionPage> {
  const session = await requireSession(locale);
  const result = await source.billing.subscription(session);
  if (result.ok) return { session, state: result.data };
  if (result.problem.status === 401) redirect(loginPath(locale, "expired"));
  return { session, problem: result.problem };
}

/** Une page d'étape n'est affichée que si elle correspond à l'état (retour arrière, favoris…). */
export function ensureStep(locale: Locale, state: SubscriptionState, expected: ReturnType<typeof stepFor>): void {
  const step = stepFor(state);
  if (step !== expected) redirect(`/${locale}/subscription/${step}`);
}

export type SocialOutcome = "ok" | "social_no_account" | "social_failed";

/**
 * Issue d'une connexion Google ou Apple. Le site ne crée pas de compte : un compte social inconnu
 * (créé à l'instant par l'API, ou refusé en not_found) renvoie vers l'app.
 */
export async function finishSocial(result: Result<AuthResult>, ctx: { locale: Locale; clientIp?: string }): Promise<SocialOutcome> {
  if (!result.ok) return result.problem.code === "not_found" ? "social_no_account" : "social_failed";
  if (result.data.created) {
    await source.auth.logout({ ...ctx, accessToken: result.data.tokens.access });
    return "social_no_account";
  }
  writeSession(await cookies(), result.data.tokens, result.data.me.email);
  return "ok";
}

/** Pages de gestion des abonnements des stores. */
export function storeManagementUrl(channel: string): string {
  if (channel === "app_store") return "https://apps.apple.com/account/subscriptions";
  return `https://play.google.com/store/account/subscriptions?package=${encodeURIComponent(env.ANDROID_PACKAGE)}`;
}
