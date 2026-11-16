import { expect, test } from "@playwright/test";

import { ACCOUNTS, expectAccessible, login } from "./support";

test.describe("Utilisateurs", () => {
  test("recherche dans l'URL, fiche, données de santé révélées avec un motif", async ({ page }) => {
    await login(page, ACCOUNTS.support, "/users");
    await page.getByRole("searchbox", { name: "Email, nom ou identifiant" }).fill("franck");
    await expect(page).toHaveURL(/q=franck/);
    await page.getByRole("link", { name: "Franck Etape" }).click();
    await expect(page.getByRole("heading", { name: /Franck Etape/ })).toBeVisible();
    await expectAccessible(page);

    await page.getByRole("button", { name: "Afficher (sera historisé)" }).click();
    const dialog = page.getByRole("dialog", { name: "Afficher les données de santé" });
    await dialog.getByLabel("Motif").fill("Demande #4821");
    await dialog.getByRole("button", { name: "Afficher (sera historisé)" }).click();
    await expect(page.getByText("Poids actuel")).toBeVisible();
  });

  test("action avec motif et confirmation forte, refusée au rôle qui ne l'a pas", async ({ page }) => {
    await login(page, ACCOUNTS.support, "/users/8f2a1c10-0000-4000-8000-000000000003");
    // Le support ne peut pas suspendre : le bouton n'existe pas.
    await expect(page.getByRole("button", { name: "Suspendre" })).toHaveCount(0);

    await page.context().clearCookies();
    await login(page, ACCOUNTS.superadmin, "/users/8f2a1c10-0000-4000-8000-000000000003");
    // L'état simulé dure autant que le serveur : on repart d'un compte actif.
    const reactivate = page.getByRole("button", { name: "Actions" });
    await expect(page.getByRole("heading", { name: "Profil" })).toBeVisible();
    if ((await page.getByRole("button", { name: "Suspendre" }).count()) === 0) {
      await reactivate.click();
      await page.getByRole("menuitem", { name: "Réactiver" }).click();
      const back = page.getByRole("dialog", { name: "Réactiver" });
      await back.getByLabel("Motif").fill("Remise en état du test");
      await back.getByRole("button", { name: "Réactiver" }).click();
      await expect(page.getByRole("button", { name: "Suspendre" })).toBeVisible();
    }
    await page.getByRole("button", { name: "Suspendre" }).click();
    const dialog = page.getByRole("dialog", { name: "Suspendre" });
    await dialog.getByLabel("Motif").fill("Fraude au parrainage");
    const confirm = dialog.getByRole("button", { name: "Suspendre" });
    await expect(confirm).toBeDisabled();
    await dialog.getByLabel(/Pour confirmer/).fill("moussa@exemple.com");
    await confirm.click();
    await expect(page.locator("main .card").getByText("Suspendu", { exact: true })).toBeVisible();
  });
});
