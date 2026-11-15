import { expect, test } from "@playwright/test";

// Une adresse IP par scénario : les formulaires sont limités par IP.
test.beforeEach(async ({ context }) => {
  await context.setExtraHTTPHeaders({ "x-real-ip": `10.1.${Math.floor(Math.random() * 250)}.${Math.floor(Math.random() * 250)}` });
});

test.describe("langue", () => {
  test("la racine renvoie vers la langue du navigateur, puis la retient", async ({ browser }) => {
    const context = await browser.newContext({ locale: "en-US", extraHTTPHeaders: { "Accept-Language": "en-US,en;q=0.9" } });
    const page = await context.newPage();
    await page.goto("/");
    await expect(page).toHaveURL(/\/en$/);
    // Menu natif <details> : le résumé ouvre la liste des langues
    await page.locator("summary", { hasText: "EN" }).first().click();
    await page.getByRole("link", { name: "Français" }).first().click();
    await expect(page).toHaveURL(/\/fr$/);
    await page.goto("/");
    await expect(page).toHaveURL(/\/fr$/);
    await context.close();
  });
});

test.describe("accueil et tarifs", () => {
  test("prix renvoyés par l'API et comparatif", async ({ page }) => {
    await page.goto("/fr/pricing");
    await expect(page.getByRole("heading", { level: 1 })).toContainText("Simple");
    await expect(page.getByText(/46,99\s\$/).first()).toBeVisible();
    await expect(page.getByRole("table", { name: /Comparatif/ })).toBeVisible();
  });
  test("le QR code et les stores sont présents", async ({ page }) => {
    await page.goto("/fr");
    await expect(page.getByRole("link", { name: /Google Play/ }).first()).toBeVisible();
    await expect(page.getByRole("img", { name: /QR code/ }).first()).toBeAttached();
  });
});

test.describe("FAQ", () => {
  test("la recherche filtre les questions et annonce le résultat", async ({ page }) => {
    await page.goto("/fr/faq", { waitUntil: "networkidle" });
    await page.getByRole("searchbox", { name: "Rechercher une question" }).fill("resilier");
    await expect(page.getByText(/questions? trouvées?/)).toBeVisible();
    await expect(page.getByText("Comment résilier ?")).toBeVisible();
    await page.getByRole("searchbox").fill("zzzz");
    await expect(page.getByText("Aucune question ne correspond à ta recherche.")).toBeVisible();
  });
});

test.describe("invitation", () => {
  test("Android : lien Play avec le code dans referrer @mobile", async ({ browser }) => {
    const context = await browser.newContext({ userAgent: "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/131 Mobile Safari/537.36" });
    const page = await context.newPage();
    await page.goto("/fr/i/awa2026");
    await expect(page.getByRole("heading", { level: 1 })).toContainText("Awa t'offre");
    const href = await page.locator("a[data-store='android']").first().getAttribute("href");
    expect(new URL(href!).searchParams.get("referrer")).toContain("invite_code=AWA2026");
    await context.close();
  });
  test("iPhone : App Store et copie du code @mobile", async ({ browser }) => {
    const context = await browser.newContext({ userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148", permissions: ["clipboard-read", "clipboard-write"] });
    const page = await context.newPage();
    await page.goto("/fr/i/AWA2026", { waitUntil: "networkidle" });
    await expect(page.locator("a[data-store='ios']").first()).toHaveAttribute("href", /apps\.apple\.com/);
    await page.getByRole("button", { name: "Copier" }).click();
    await expect(page.getByRole("button", { name: "Code copié" })).toBeVisible();
    await context.close();
  });
  test("code invalide", async ({ page }) => {
    await page.goto("/fr/i/NOPE99");
    await expect(page.getByRole("heading", { level: 1 })).toContainText("n'est plus valable");
  });
});

test.describe("formulaires publics", () => {
  test("contact : crée une demande", async ({ page }) => {
    await page.goto("/fr/contact", { waitUntil: "networkidle" });
    await page.getByLabel("Nom").fill("Awa Diallo");
    await page.getByLabel("Email").fill("awa@example.com");
    await page.getByLabel("Catégorie").selectOption("billing");
    await page.getByLabel("Sujet").fill("Question de paiement");
    await page.getByLabel("Message").fill("Bonjour, j'ai une question sur mon abonnement.");
    await page.getByRole("checkbox").check();
    await page.getByRole("button", { name: "Envoyer" }).click();
    await expect(page.getByRole("status")).toContainText(/NY-\d+/);
  });
  test("suppression : demande, lien reçu puis confirmation explicite", async ({ page }) => {
    await page.goto("/fr/delete-account", { waitUntil: "networkidle" });
    await page.getByLabel("Email du compte").fill("free@omeo.demo");
    await page.getByRole("button", { name: "Envoyer le lien de confirmation" }).click();
    await expect(page.getByText("Vérifie ta boîte mail")).toBeVisible();
    await page.getByRole("link", { name: /Ouvrir le lien de confirmation/ }).click();
    await page.getByRole("button", { name: "Supprimer définitivement mon compte" }).click();
    await expect(page.getByText("Suppression programmée")).toBeVisible();
    // Le même lien ne sert qu'une fois
    await page.reload();
    await page.getByRole("button", { name: "Supprimer définitivement mon compte" }).click();
    await expect(page.getByText(/invalide ou a expiré/)).toBeVisible();
  });
  test("lien de suppression incomplet", async ({ page }) => {
    await page.goto("/fr/delete-account/confirm");
    await expect(page.getByText(/incomplet/)).toBeVisible();
  });
});

test.describe("sécurité", () => {
  test("CSP à nonce et en-têtes", async ({ request }) => {
    const response = await request.get("/fr");
    const csp = response.headers()["content-security-policy"] ?? "";
    expect(csp).toMatch(/script-src 'self' 'nonce-[^']+' 'strict-dynamic'/);
    expect(csp).toContain("frame-ancestors 'none'");
    expect(response.headers()["x-frame-options"]).toBe("DENY");
    expect(response.headers()["referrer-policy"]).toBe("strict-origin-when-cross-origin");
  });
  test("mutation d'une autre origine refusée, endpoint hors liste blanche introuvable", async ({ request }) => {
    expect((await request.post("/api/me/billing/promo-check", { headers: { Origin: "https://evil.example" }, data: {} })).status()).toBe(403);
    expect((await request.get("/api/admin/users")).status()).toBe(404);
    expect((await request.get("/api/me/subscription")).status()).toBe(401);
  });
});
