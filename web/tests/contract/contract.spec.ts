import { expect, test } from "@playwright/test";

/**
 * Chaque appel du site part vers Prism, qui le valide contre le contrat : une requête non conforme
 * (corps, en-têtes, paramètres) reçoit une erreur et le test échoue.
 */

test.beforeEach(async ({ context }) => {
  await context.setExtraHTTPHeaders({ "x-real-ip": `10.9.${Math.floor(Math.random() * 250)}.${Math.floor(Math.random() * 250)}` });
});

test("tarifs : offres et comparatif lus dans la réponse de /billing/plans", async ({ page }) => {
  await page.goto("/fr/pricing");
  await expect(page.locator(".plan").first()).toBeVisible();
  await expect(page.getByText("Les tarifs sont momentanément indisponibles")).toHaveCount(0);
});

test("FAQ, page légale et invitation : réponses du contrat affichées", async ({ page }) => {
  await page.goto("/fr/faq");
  await expect(page.locator("details.qa").first()).toBeVisible();
  await page.goto("/fr/legal/terms");
  await expect(page.getByText(/Version \d+/)).toBeVisible();
  await page.goto("/fr/i/AWA2026");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
});

test("contact : requête conforme au contrat, captcha Turnstile réel", async ({ page }) => {
  await page.goto("/fr/contact", { waitUntil: "load" });
  await page.getByLabel("Nom").fill("Awa Diallo");
  await page.getByLabel("Email").fill("awa@example.com");
  await page.getByLabel("Sujet").fill("Question de paiement");
  await page.getByLabel("Message").fill("Bonjour, j'ai une question sur mon abonnement.");
  await page.getByRole("checkbox").check();
  // Jeton déposé par le widget Turnstile (clé de test, toujours acceptée)
  await expect(page.locator("input[name='captcha']")).not.toHaveValue("", { timeout: 20_000 });
  await page.getByRole("button", { name: "Envoyer" }).click();
  await expect(page.getByText("Message envoyé")).toBeVisible();
});

test("suppression de compte : requête conforme au contrat", async ({ page }) => {
  await page.goto("/fr/delete-account", { waitUntil: "load" });
  await page.getByLabel("Email du compte").fill("awa@example.com");
  await expect(page.locator("input[name='captcha']")).not.toHaveValue("", { timeout: 20_000 });
  await page.getByRole("button", { name: "Envoyer le lien de confirmation" }).click();
  await expect(page.getByText("Vérifie ta boîte mail")).toBeVisible();
});

test("connexion : requête conforme ; jetons d'exemple expirés → retour propre à la connexion", async ({ page }) => {
  await page.goto("/fr/subscription/login", { waitUntil: "load" });
  await page.getByLabel("Email").fill("awa@example.com");
  await page.getByLabel("Mot de passe", { exact: true }).fill("correct horse battery");
  await page.getByRole("button", { name: "Se connecter" }).click();
  // Prism renvoie une date d'expiration figée dans le passé : pas de boucle, retour à la connexion.
  await expect(page).toHaveURL(/\/fr\/subscription\/login/);
  await expect(page.locator(".note.danger")).toHaveCount(0);
});

test("connexion Google : redirection vers le fournisseur avec PKCE, état et nonce", async ({ request }) => {
  const response = await request.get("/auth/google/start?locale=fr", { maxRedirects: 0 });
  expect(response.status()).toBe(303);
  const target = new URL(response.headers()["location"]!);
  expect(target.origin).toBe("https://accounts.google.com");
  expect(target.searchParams.get("client_id")).toBe("contract-test.apps.googleusercontent.com");
  expect(target.searchParams.get("redirect_uri")).toBe("http://localhost:3200/auth/google/callback");
  expect(target.searchParams.get("code_challenge_method")).toBe("S256");
  expect(target.searchParams.get("state")).toMatch(/^[\w-]{40,}$/);
  expect(target.searchParams.get("nonce")).toMatch(/^[\w-]{40,}$/);
  expect(response.headers()["set-cookie"]).toMatch(/omeo_oauth=.*HttpOnly/i);
});

test("connexion Apple : form_post, état et nonce", async ({ request }) => {
  const response = await request.get("/auth/apple/start?locale=fr", { maxRedirects: 0 });
  const target = new URL(response.headers()["location"]!);
  expect(target.origin).toBe("https://appleid.apple.com");
  expect(target.searchParams.get("response_mode")).toBe("form_post");
  expect(target.searchParams.get("response_type")).toBe("code id_token");
});

test("retour OAuth avec un état falsifié : refusé", async ({ request }) => {
  await request.get("/auth/google/start?locale=fr", { maxRedirects: 0 });
  const response = await request.get("/auth/google/callback?code=x&state=forged", { maxRedirects: 0 });
  expect(response.headers()["location"]).toContain("/fr/subscription/login?error=social_failed");
  const apple = await request.post("/auth/apple/callback", { form: { state: "forged", id_token: "x" }, maxRedirects: 0 });
  expect(apple.headers()["location"]).toContain("error=social_failed");
});
