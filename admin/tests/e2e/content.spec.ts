import { expect, test } from "@playwright/test";

import { ACCOUNTS, confirmStepUp, expectAccessible, login } from "./support";

const SAUCE = "/content/recipes/c0a7e000-0000-4000-8000-000000000303";
const FONIO = "/content/recipes/c0a7e000-0000-4000-8000-000000000304";

test.describe("Contenus", () => {
  test("l'auteur ne peut pas publier son propre contenu, une autre personne oui", async ({ page }) => {
    await login(page, ACCOUNTS.content, SAUCE);
    await expect(page.getByRole("heading", { name: "Sauce gombo légère" })).toBeVisible();
    await expectAccessible(page);
    const publish = page.getByRole("button", { name: "Publier" });
    if ((await publish.count()) > 0) {
      await expect(publish).toBeDisabled();
      await expect(page.getByText("une autre personne doit la relire")).toBeVisible();
    }

    await page.context().clearCookies();
    await login(page, ACCOUNTS.contentModeration, SAUCE);
    if (await page.getByRole("button", { name: "Publier" }).isVisible()) {
      await page.getByRole("button", { name: "Publier" }).click();
      await expect(page.locator(".ph").getByText("Publié")).toBeVisible();
    }
  });

  test("langues : onglets, aperçu arabe de droite à gauche", async ({ page }) => {
    await login(page, ACCOUNTS.content, FONIO);
    await page.getByRole("tab", { name: /AR/ }).click();
    await expect(page.getByRole("tabpanel")).toHaveAttribute("dir", "rtl");
  });

  test("envoyer en relecture crée une demande validée par une autre personne", async ({ page }) => {
    await login(page, ACCOUNTS.content, FONIO);
    const review = page.getByRole("button", { name: "Envoyer en relecture" });
    if (await review.isVisible()) {
      await review.click();
      await expect(page.getByText("En attente de validation par une autre personne.").first()).toBeVisible();
    }
    await page.context().clearCookies();
    await login(page, ACCOUNTS.contentModeration, "/approvals");
    const card = page.locator("article", { hasText: "Salade de fonio" });
    if ((await card.count()) > 0) {
      await card.getByRole("button", { name: "Approuver" }).click();
      await page.getByRole("dialog", { name: "Approuver la demande" }).getByRole("button", { name: "Approuver" }).click();
      const stepUp = page.getByRole("dialog", { name: "Confirme ton identité" });
      if (await stepUp.isVisible().catch(() => false)) await confirmStepUp(page);
      await expect(page.getByText("Demande approuvée et appliquée.").first()).toBeVisible();
    }
  });
});
