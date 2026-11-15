import { expect, test, type Page } from "@playwright/test";

const PASSWORD = "omeo-demo";

// Une adresse IP par scénario : la limitation de débit de la connexion est comptée par IP.
test.beforeEach(async ({ context }, info) => {
  await context.setExtraHTTPHeaders({ "x-real-ip": `10.0.${info.workerIndex % 250}.${(info.testId.charCodeAt(0) + info.repeatEachIndex + Math.floor(Math.random() * 200)) % 250}` });
});

async function login(page: Page, email: string) {
  await page.goto("/fr/subscription");
  await expect(page).toHaveURL(/\/fr\/subscription\/login/);
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Mot de passe", { exact: true }).fill(PASSWORD);
  await page.getByRole("button", { name: "Se connecter" }).click();
}

test("parcours complet : connexion, offre, code promo, paiement simulé, activation, gestion, résiliation @mobile", async ({ page }) => {
  await login(page, "essai@omeo.demo");
  await expect(page).toHaveURL(/\/fr\/subscription\/plan/);
  await expect(page.getByText("essai Plus", { exact: true })).toBeVisible();

  // Offre annuelle mise en avant, code promo vérifié par l'API
  await expect(page.getByRole("radio", { name: /Annuel/ })).toBeChecked();
  await page.getByRole("button", { name: "Ajouter" }).click();
  await page.getByLabel("Code promo").fill("FAUX");
  await page.getByRole("button", { name: "Appliquer" }).click();
  await expect(page.getByText("Ce code promo n'est pas valable pour cette offre.")).toBeVisible();
  await page.getByLabel("Code promo").fill("BIENVENUE20");
  await page.getByRole("button", { name: "Appliquer" }).click();
  await expect(page.getByText(/37,59\s\$ au lieu de 46,99\s\$/)).toBeVisible();

  await page.getByRole("button", { name: "Continuer vers le paiement" }).click();
  await expect(page).toHaveURL(/mock-checkout\?session=/);
  await expect(page.getByText(/Montant : 37,59/)).toBeVisible();
  await page.getByRole("button", { name: "Paiement accepté" }).click();

  // Retour en succès : attente de l'activation par le webhook simulé
  await expect(page).toHaveURL(/\/fr\/subscription\/success/);
  await expect(page.getByRole("heading", { name: "Bienvenue dans Omeo Plus !" })).toBeVisible({ timeout: 20_000 });

  await page.getByRole("link", { name: "Gérer mon abonnement" }).click();
  await expect(page).toHaveURL(/\/fr\/subscription\/manage/);
  await expect(page.getByText(/37,59/).first()).toBeVisible();

  // Portail simulé : résiliation, Plus reste actif jusqu'à la fin de période
  await page.getByRole("button", { name: "Gérer sur la page de paiement" }).click();
  await page.getByRole("button", { name: "Résilier l'abonnement" }).click();
  await page.getByRole("link", { name: "Revenir sur Omeo" }).click();
  await expect(page.getByText("Résilié")).toBeVisible();
  await expect(page.getByText(/Actif jusqu'au/)).toBeVisible();

  // Retour arrière vers l'offre : renvoyé vers la gestion (pas de second paiement)
  await page.goto("/fr/subscription/plan");
  await expect(page).toHaveURL(/\/fr\/subscription\/manage/);
});

test("paiement refusé puis abandonné", async ({ page }) => {
  await login(page, "free@omeo.demo");
  await page.getByRole("button", { name: "Continuer vers le paiement" }).click();
  await page.getByRole("button", { name: "Paiement refusé" }).click();
  await expect(page).toHaveURL(/failed\?status=failed/);
  await expect(page.getByText("Paiement refusé.")).toBeVisible();
  await page.getByRole("link", { name: "Réessayer" }).click();
  await page.getByRole("button", { name: "Continuer vers le paiement" }).click();
  await page.getByRole("button", { name: "Abandonner" }).click();
  await expect(page.getByText("Paiement annulé.")).toBeVisible();
});

test("abonnement pris dans un store : pas de double abonnement", async ({ page }) => {
  await login(page, "store@omeo.demo");
  await expect(page).toHaveURL(/\/fr\/subscription\/store/);
  await expect(page.getByRole("heading", { level: 1 })).toContainText("Google Play");
  await expect(page.getByRole("link", { name: "Ouvrir Google Play" })).toHaveAttribute("href", /play\.google\.com/);
  await page.goto("/fr/subscription/plan");
  await expect(page).toHaveURL(/\/fr\/subscription\/store/);
});

test("paiement en échec : avertissement sur la page de gestion", async ({ page }) => {
  await login(page, "echec@omeo.demo");
  await expect(page).toHaveURL(/\/fr\/subscription\/manage/);
  await expect(page.getByText(/Le dernier paiement a échoué/)).toBeVisible();
  await expect(page.getByText(/· Échoué$/)).toBeVisible();
});

test("email non vérifié : paiement refusé avec le bon message", async ({ page }) => {
  await login(page, "nonverifie@omeo.demo");
  await page.getByRole("button", { name: "Continuer vers le paiement" }).click();
  await expect(page.locator(".note.danger")).toContainText("Confirme d'abord ton adresse email");
});

test("identifiants refusés, puis connexion sociale simulée d'un compte inconnu", async ({ page }) => {
  await page.goto("/fr/subscription/login");
  await page.getByLabel("Email").fill("free@omeo.demo");
  await page.getByLabel("Mot de passe", { exact: true }).fill("mauvais");
  await page.getByRole("button", { name: "Se connecter" }).click();
  await expect(page.locator(".note.danger")).toContainText("Email ou mot de passe incorrect.");

  await page.getByRole("link", { name: "Continuer avec Google" }).click();
  await page.getByRole("button", { name: /Compte inconnu/ }).click();
  await expect(page.locator(".note.danger")).toContainText("Aucun compte Omeo n'est associé");
});

test("connexion Apple simulée puis déconnexion", async ({ page }) => {
  await page.goto("/fr/subscription/login");
  await page.getByRole("link", { name: "Continuer avec Apple" }).click();
  await page.getByRole("button", { name: /plus@omeo\.demo/ }).click();
  await expect(page).toHaveURL(/\/fr\/subscription\/manage/);
  await page.getByRole("button", { name: "Se déconnecter" }).click();
  await expect(page).toHaveURL(/\/fr\/subscription\/login/);
  await page.goto("/fr/subscription/manage");
  await expect(page).toHaveURL(/\/fr\/subscription\/login/);
});

test("session expirée : renouvelée côté serveur sans nouvelle connexion", async ({ page, context }) => {
  await login(page, "plus@omeo.demo");
  await expect(page).toHaveURL(/\/fr\/subscription\/manage/);
  // Le jeton d'accès disparaît (expiré) : seul le jeton de renouvellement reste
  const cookies = await context.cookies();
  await context.clearCookies();
  await context.addCookies(cookies.filter((c) => c.name !== "omeo_at" && c.name !== "omeo_exp"));
  await page.goto("/fr/subscription/manage");
  await expect(page).toHaveURL(/\/fr\/subscription\/manage/);
  expect((await context.cookies()).some((c) => c.name === "omeo_at" && c.httpOnly)).toBe(true);
});
