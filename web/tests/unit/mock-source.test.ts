import { describe, expect, it, vi } from "vitest";

import source from "@/server/data/mock";
import { ACTIVATION_DELAY_MS } from "@/server/data/mock/state";
import type { AuthedContext, Result } from "@/server/data/types";

/** Règles métier simulées : mêmes formes et mêmes codes d'erreur que le contrat. */
const ctx = { locale: "fr" as const };
const PASSWORD = "omeo-demo";
const SITE = "https://my-omeo.test";

function ok<T>(result: Result<T>): T {
  if (!result.ok) throw new Error(`attendu ok, reçu ${result.problem.code}`);
  return result.data;
}

function code(result: Result<unknown>): string | undefined {
  return result.ok ? undefined : result.problem.code;
}

async function signIn(email: string): Promise<AuthedContext> {
  const auth = ok(await source.auth.login(email, PASSWORD, ctx));
  return { ...ctx, accessToken: auth.tokens.access };
}

const checkoutInput = (plan: "plus_monthly" | "plus_annual", promo?: string) => ({
  plan_code: plan,
  ...(promo ? { promo_code: promo } : {}),
  success_url: `${SITE}/fr/subscription/success`,
  cancel_url: `${SITE}/fr/subscription/failed`,
});

describe("connexion", () => {
  it("accepte un compte de démo et renvoie le profil", async () => {
    const auth = ok(await source.auth.login("Free@Omeo.demo ", PASSWORD, ctx));
    expect(auth.me.email).toBe("free@omeo.demo");
    expect(auth.created).toBe(false);
  });
  it("refuse un mauvais mot de passe ou un compte inconnu avec le même code", async () => {
    expect(code(await source.auth.login("free@omeo.demo", "faux", ctx))).toBe("invalid_credentials");
    expect(code(await source.auth.login("inconnu@omeo.demo", PASSWORD, ctx))).toBe("invalid_credentials");
  });
  it("simule la limitation de débit", async () => {
    expect(code(await source.auth.login("trop@omeo.demo", PASSWORD, ctx))).toBe("rate_limited");
  });
  it("connexion sociale : compte connu, compte inconnu (not_found), jeton forgé", async () => {
    const demo = source.demo!;
    expect(ok(await source.auth.social("google", demo.socialIdToken("plus@omeo.demo"), undefined, ctx)).me.email).toBe("plus@omeo.demo");
    expect(code(await source.auth.social("apple", demo.socialIdToken(null), undefined, ctx))).toBe("not_found");
    expect(code(await source.auth.social("google", "forged", undefined, ctx))).toBe("invalid_credentials");
  });
});

describe("renouvellement de session", () => {
  it("fait tourner les jetons et ferme la session si un ancien jeton est rejoué", async () => {
    const auth = ok(await source.auth.login("free@omeo.demo", PASSWORD, ctx));
    const next = ok(await source.auth.refresh(auth.tokens.refresh, ctx));
    expect(next.refresh).not.toBe(auth.tokens.refresh);
    expect(code(await source.auth.refresh(auth.tokens.refresh, ctx))).toBe("token_expired");
    // Rejeu détecté : la session entière est fermée, même le nouveau jeton.
    expect(code(await source.auth.refresh(next.refresh, ctx))).toBe("token_expired");
  });
  it("ferme la session à la déconnexion", async () => {
    const session = await signIn("free@omeo.demo");
    ok(await source.auth.logout(session));
    expect(code(await source.billing.subscription(session))).toBe("not_authenticated");
  });
  it("refuse un jeton inconnu", async () => {
    expect(code(await source.billing.subscription({ ...ctx, accessToken: "x" }))).toBe("token_expired");
  });
});

describe("abonnement", () => {
  it("donne l'étape de chaque scénario par can_manage", async () => {
    const expected: Record<string, string> = {
      "essai@omeo.demo": "none",
      "free@omeo.demo": "none",
      "plus@omeo.demo": "web",
      "store@omeo.demo": "store",
      "echec@omeo.demo": "web",
      "offert@omeo.demo": "none",
    };
    for (const [email, canManage] of Object.entries(expected)) {
      const state = ok(await source.billing.subscription(await signIn(email)));
      expect(state.can_manage, email).toBe(canManage);
    }
  });
  it("simule une panne serveur", async () => {
    expect(code(await source.billing.subscription(await signIn("panne@omeo.demo")))).toBe("server_error");
  });
  it("paiement accepté : actif seulement après le webhook simulé", async () => {
    vi.useFakeTimers({ now: new Date("2026-11-15T10:00:00Z") });
    const session = await signIn("free@omeo.demo");
    const checkout = ok(await source.billing.checkout(checkoutInput("plus_annual"), crypto.randomUUID(), session));
    const id = new URL(checkout.checkout_url).searchParams.get("session")!;
    expect(new URL(checkout.checkout_url).pathname).toBe("/fr/subscription/mock-checkout");

    expect(source.demo!.completeCheckout(id, "success")).toBe(`${SITE}/fr/subscription/success`);
    expect(ok(await source.billing.subscription(session)).can_manage).toBe("none");

    vi.advanceTimersByTime(ACTIVATION_DELAY_MS);
    const active = ok(await source.billing.subscription(session));
    expect(active.can_manage).toBe("web");
    expect(active.subscription?.plan_code).toBe("plus_annual");
    expect(ok(await source.billing.payments(undefined, session)).results?.[0]?.status).toBe("succeeded");
    // Session de paiement à usage unique
    expect(source.demo!.completeCheckout(id, "success")).toBeUndefined();
  });
  it("paiement refusé ou abandonné : retour sur cancel_url avec le statut", async () => {
    const session = await signIn("free@omeo.demo");
    for (const [outcome, status] of [["failure", "failed"], ["abandon", "canceled"]] as const) {
      const checkout = ok(await source.billing.checkout(checkoutInput("plus_monthly"), crypto.randomUUID(), session));
      const id = new URL(checkout.checkout_url).searchParams.get("session")!;
      expect(source.demo!.completeCheckout(id, outcome)).toBe(`${SITE}/fr/subscription/failed?status=${status}`);
    }
  });
  it("code promo : remise calculée par la source, refus d'un code inconnu", async () => {
    const session = await signIn("free@omeo.demo");
    const promo = ok(await source.billing.promoCheck({ code: "bienvenue20", plan_code: "plus_annual" }, session));
    expect(promo).toMatchObject({ valid: true, discounted: { amount_cents: 3759 }, original: { amount_cents: 4699 } });
    expect(ok(await source.billing.promoCheck({ code: "NOPE", plan_code: "plus_annual" }, session)).valid).toBe(false);
    expect(code(await source.billing.checkout(checkoutInput("plus_annual", "NOPE"), crypto.randomUUID(), session))).toBe("validation_error");
  });
  it("refuse le paiement sans email vérifié, en double avec un store, ou vers un autre site", async () => {
    expect(code(await source.billing.checkout(checkoutInput("plus_monthly"), crypto.randomUUID(), await signIn("nonverifie@omeo.demo")))).toBe("email_not_verified");
    expect(code(await source.billing.checkout(checkoutInput("plus_monthly"), crypto.randomUUID(), await signIn("store@omeo.demo")))).toBe("conflict");
    const evil = { ...checkoutInput("plus_monthly"), success_url: "https://evil.example/ok" };
    expect(code(await source.billing.checkout(evil, crypto.randomUUID(), await signIn("free@omeo.demo")))).toBe("validation_error");
  });
  it("portail : réservé à un abonnement web ; la résiliation garde Plus jusqu'à la fin de période", async () => {
    expect(code(await source.billing.portal(`${SITE}/fr/subscription/manage`, await signIn("free@omeo.demo")))).toBe("conflict");
    vi.useFakeTimers({ now: new Date("2026-11-15T10:00:00Z") });
    const session = await signIn("essai@omeo.demo");
    const checkout = ok(await source.billing.checkout(checkoutInput("plus_monthly"), crypto.randomUUID(), session));
    source.demo!.completeCheckout(new URL(checkout.checkout_url).searchParams.get("session")!, "success");
    vi.advanceTimersByTime(ACTIVATION_DELAY_MS);
    expect(ok(await source.billing.portal(`${SITE}/fr/subscription/manage`, session)).url).toContain("/fr/subscription/mock-portal");
    expect(source.demo!.setAutoRenew(session.accessToken, false)).toBe(true);
    const state = ok(await source.billing.subscription(session));
    expect(state.subscription).toMatchObject({ status: "canceled", auto_renew: false });
    expect(state.entitlements.tier).toBe("plus");
  });
});

describe("contenus et formulaires", () => {
  it("offres : annuelle mise en avant, prix formatés par langue", async () => {
    const fr = ok(await source.content.plans("fr"));
    expect(fr.plans.find((p) => p.featured)?.code).toBe("plus_annual");
    expect(fr.plans.find((p) => p.code === "plus_monthly")?.price.formatted).toMatch(/^4,49\s\$$/u);
    expect(ok(await source.content.plans("en")).plans.find((p) => p.code === "plus_monthly")?.price.formatted).toBe("$4.49");
  });
  it("une langue sans contenu suit le repli de l'API", async () => {
    expect(ok(await source.content.faq("de"))).toEqual(ok(await source.content.faq("en")));
  });
  it("vérifie les codes d'invitation", async () => {
    expect(ok(await source.referral.check("awa2026", ctx))).toMatchObject({ valid: true, referrer_first_name: "Awa", trial_days: 7 });
    expect(ok(await source.referral.check("INCONNU", ctx)).valid).toBe(false);
  });
  it("numérote les demandes de support", async () => {
    const a = ok(await source.support.createTicket({ category: "question", subject: "Bonjour", message: "Une question" }, crypto.randomUUID(), ctx));
    const b = ok(await source.support.createTicket({ category: "question", subject: "Bonjour", message: "Une question" }, crypto.randomUUID(), ctx));
    expect(a.number).toMatch(/^NY-\d+$/);
    expect(b.number).not.toBe(a.number);
  });
  it("suppression : même réponse que le compte existe ou non ; lien à usage unique", async () => {
    const before = source.demo!.lastDeletionToken();
    ok(await source.accountDeletion.request("personne@omeo.demo", "", ctx));
    expect(source.demo!.lastDeletionToken()).toBe(before);
    ok(await source.accountDeletion.request("free@omeo.demo", "", ctx));
    const token = source.demo!.lastDeletionToken()!;
    ok(await source.accountDeletion.confirm(token, ctx));
    const again = await source.accountDeletion.confirm(token, ctx);
    expect(again.ok ? undefined : Object.keys(again.problem.errors ?? {})).toEqual(["token"]);
  });
});
