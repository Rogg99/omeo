import { describe, expect, it } from "vitest";

import { hit } from "@/server/rate-limit";
import { sign, verifySignature } from "@/server/revalidate-signature";
import { EXPIRY_MARGIN_MS, isAccessFresh, safeNextPath } from "@/server/session-cookies";

describe("isAccessFresh", () => {
  const now = 1_000_000;
  it("accepte un jeton qui expire après la marge", () => {
    expect(isAccessFresh(String(now + EXPIRY_MARGIN_MS + 1), now)).toBe(true);
  });
  it("refuse un jeton qui expire dans la marge, déjà expiré, absent ou illisible", () => {
    expect(isAccessFresh(String(now + EXPIRY_MARGIN_MS), now)).toBe(false);
    expect(isAccessFresh(String(now - 1), now)).toBe(false);
    expect(isAccessFresh(undefined, now)).toBe(false);
    expect(isAccessFresh("abc", now)).toBe(false);
  });
});

describe("safeNextPath", () => {
  it("garde un chemin du site", () => {
    expect(safeNextPath("/fr/subscription/plan?plan=plus_annual", "/x")).toBe("/fr/subscription/plan?plan=plus_annual");
  });
  it.each(["https://evil.example", "//evil.example", "/\\evil.example", "javascript:alert(1)", "", null, undefined])("refuse %s (redirection ouverte)", (value) => {
    expect(safeNextPath(value, "/fallback")).toBe("/fallback");
  });
});

describe("hit (limitation de débit)", () => {
  const rule = { limit: 2, windowMs: 1000 };
  it("bloque au-delà de la limite puis rouvre après la fenêtre", () => {
    expect(hit("k", rule, 0).ok).toBe(true);
    expect(hit("k", rule, 10).ok).toBe(true);
    const blocked = hit("k", rule, 20);
    expect(blocked).toEqual({ ok: false, retryAfterSeconds: 1 });
    expect(hit("k", rule, 1001).ok).toBe(true);
  });
  it("compte chaque clé séparément", () => {
    hit("a", rule, 0);
    hit("a", rule, 0);
    expect(hit("b", rule, 0).ok).toBe(true);
  });
});

describe("signature du webhook de revalidation", () => {
  const secret = "s".repeat(32);
  const body = JSON.stringify({ tags: ["faq"] });
  const now = 1_700_000_000;
  it("accepte une signature valide et récente", () => {
    expect(verifySignature(secret, String(now), sign(secret, String(now), body), body, now + 10)).toBe(true);
  });
  it("refuse un corps modifié, un autre secret, une signature trop ancienne ou absente", () => {
    const signature = sign(secret, String(now), body);
    expect(verifySignature(secret, String(now), signature, `${body} `, now)).toBe(false);
    expect(verifySignature("t".repeat(32), String(now), signature, body, now)).toBe(false);
    expect(verifySignature(secret, String(now), signature, body, now + 301)).toBe(false);
    expect(verifySignature(secret, null, signature, body, now)).toBe(false);
    expect(verifySignature(secret, String(now), null, body, now)).toBe(false);
    expect(verifySignature(secret, "12a", signature, body, now)).toBe(false);
  });
});

describe("compatibilité avec l'API (apps/core/web_cache.py)", () => {
  it("produit la même signature que le vecteur partagé", () => {
    expect(sign("s".repeat(32), "1700000000", '{"tags":["faq"]}')).toBe("sha256=2354b238d08b33e682eb7f7a3105c795e25c01075441f756a88eeb9c05139808");
  });
});
