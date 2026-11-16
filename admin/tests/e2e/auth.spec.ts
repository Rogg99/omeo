import { expect, test } from "@playwright/test";

import { ACCOUNTS, PASSWORD, expectAccessible, login } from "./support";

test.describe("Connexion et autorisations", () => {
  test("sans session, toute page renvoie à la connexion", async ({ page }) => {
    await page.goto("/users");
    await expect(page).toHaveURL(/\/login\?next=%2Fusers/);
    await expect(page.getByRole("heading", { name: "Connexion" })).toBeVisible();
    await page.waitForLoadState("networkidle");
    await expectAccessible(page);
  });

  test("connexion avec double authentification, puis retour à la page demandée", async ({ page }) => {
    await login(page, ACCOUNTS.superadmin, "/users");
    await expect(page).toHaveURL(/\/users$/);
  });

  test("mauvais mot de passe : message d'erreur, pas de session", async ({ page }) => {
    await page.goto("/login");
    await page.getByLabel("Email").fill(ACCOUNTS.superadmin);
    await page.getByLabel("Mot de passe").fill(`${PASSWORD}x`);
    await page.getByRole("button", { name: "Continuer" }).click();
    await expect(page.locator("form .note.err")).toBeVisible();
    await expect(page).toHaveURL(/\/login/);
  });

  test("mauvais code TOTP : refusé", async ({ page }) => {
    await page.goto("/login");
    await page.getByLabel("Email").fill(ACCOUNTS.support);
    await page.getByLabel("Mot de passe").fill(PASSWORD);
    await page.getByRole("button", { name: "Continuer" }).click();
    await page.getByLabel("Code").fill("123456");
    await page.getByRole("button", { name: "Vérifier" }).click();
    await expect(page.locator("#code-error")).toHaveText("Code incorrect. Réessaie.");
  });

  test("le menu est filtré par permission", async ({ page }) => {
    await login(page, ACCOUNTS.moderation);
    const menu = page.locator("aside.side nav");
    await expect(menu.getByRole("link", { name: "Avis sur les analyses" })).toBeVisible();
    await expect(menu.getByRole("link", { name: "Utilisateurs" })).toHaveCount(0);
    await expect(menu.getByRole("link", { name: "Réglages" })).toHaveCount(0);
    await expectAccessible(page);
  });

  test("une page non permise affiche l'écran d'accès refusé", async ({ page }) => {
    await login(page, ACCOUNTS.moderation);
    await page.goto("/users");
    await expect(page.getByRole("heading", { name: "Accès refusé" })).toBeVisible();
  });

  test("première connexion : enrôlement obligatoire de la double authentification", async ({ page }) => {
    await page.goto("/login");
    await page.getByLabel("Email").fill(ACCOUNTS.enrollment);
    await page.getByLabel("Mot de passe").fill(PASSWORD);
    await page.getByRole("button", { name: "Continuer" }).click();
    await expect(page).toHaveURL(/\/enroll$/);
    await page.getByRole("button", { name: "Commencer" }).click();
    await expect(page.getByRole("img", { name: "QR code" })).toBeVisible();
    await page.getByLabel("J'ai rangé mes codes de secours en lieu sûr").check();
    await page.getByLabel("Saisis le code affiché par l'application pour confirmer.").fill("000000");
    await page.getByRole("button", { name: "Activer" }).click();
    await expect(page.locator("aside.side")).toBeVisible();
  });
});
