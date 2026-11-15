import { describe, expect, it } from "vitest";

import { normalize } from "@/components/FaqSearch";
import { headingsOf, slugify } from "@/components/Markdown";
import { languageAlternates, localizedUrl } from "@/lib/seo";
import { normalizeInviteCode, platformOf, playStoreUrl, storeUrlFor } from "@/server/stores";
import { stepFor } from "@/server/subscription";

describe("stores", () => {
  it("reconnaît la plateforme d'après le User-Agent", () => {
    expect(platformOf("Mozilla/5.0 (Linux; Android 14; Pixel 8)")).toBe("android");
    expect(platformOf("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)")).toBe("ios");
    expect(platformOf("Mozilla/5.0 (Windows NT 10.0; Win64; x64)")).toBe("other");
    expect(platformOf(null)).toBe("other");
  });
  it("normalise un code d'invitation et refuse un code invalide", () => {
    expect(normalizeInviteCode(" awa2026 ")).toBe("AWA2026");
    expect(normalizeInviteCode("a")).toBeUndefined();
    expect(normalizeInviteCode("AWA 2026")).toBeUndefined();
    expect(normalizeInviteCode("<script>")).toBeUndefined();
  });
  it("transmet le code à Google Play par le paramètre referrer", () => {
    const url = new URL(playStoreUrl("AWA2026"));
    expect(url.searchParams.get("id")).toBe("app.omeo");
    expect(url.searchParams.get("referrer")).toBe("utm_source=invite&utm_medium=web&invite_code=AWA2026");
    expect(new URL(playStoreUrl()).searchParams.has("referrer")).toBe(false);
  });
  it("ne renvoie vers aucun store sur ordinateur", () => {
    expect(storeUrlFor("other")).toBeUndefined();
    expect(storeUrlFor("ios")).toBe("https://apps.apple.com/app/id6740000000");
  });
});

describe("seo", () => {
  it("construit l'adresse d'une page par langue", () => {
    expect(localizedUrl("https://x.app", "fr", "/")).toBe("https://x.app/fr");
    expect(localizedUrl("https://x.app", "en", "/pricing")).toBe("https://x.app/en/pricing");
  });
  it("liste les 8 langues et x-default", () => {
    const alternates = languageAlternates("https://x.app", "/faq");
    expect(Object.keys(alternates)).toHaveLength(9);
    expect(alternates["x-default"]).toBe("https://x.app/fr/faq");
    expect(alternates["ar"]).toBe("https://x.app/ar/faq");
  });
});

describe("étape de la page Abonnement", () => {
  it("suit can_manage renvoyé par l'API", () => {
    expect(stepFor({ can_manage: "store" })).toBe("store");
    expect(stepFor({ can_manage: "web" })).toBe("manage");
    expect(stepFor({ can_manage: "none" })).toBe("plan");
  });
});

describe("texte", () => {
  it("crée des ancres stables, accents retirés", () => {
    expect(slugify("Données personnelles & cookies")).toBe("donnees-personnelles-cookies");
    expect(headingsOf("# T\n## Article 1 — *Objet*\ntexte\n## Durée")).toEqual([
      { id: "article-1-objet", title: "Article 1 — Objet" },
      { id: "duree", title: "Durée" },
    ]);
  });
  it("recherche sans tenir compte des accents ni de la casse", () => {
    expect(normalize("Ndolé")).toBe("ndole");
  });
});

describe("adresse IP du visiteur", () => {
  it("préfère X-Real-IP posée par nginx", async () => {
    const { clientIpFrom } = await import("@/server/request");
    expect(clientIpFrom(new Headers({ "x-real-ip": "203.0.113.9", "x-forwarded-for": "1.2.3.4, 203.0.113.9" }))).toBe("203.0.113.9");
  });
  it("ignore les adresses falsifiables en tête de X-Forwarded-For", async () => {
    const { clientIpFrom } = await import("@/server/request");
    expect(clientIpFrom(new Headers({ "x-forwarded-for": "6.6.6.6, 203.0.113.9" }))).toBe("203.0.113.9");
    expect(clientIpFrom(new Headers())).toBeUndefined();
  });
});
