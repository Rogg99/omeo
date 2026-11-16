import AxeBuilder from "@axe-core/playwright";
import { expect, type Page } from "@playwright/test";

/** Comptes de démonstration du mode mock (src/server/mock/fixtures/staff.ts). */
export const ACCOUNTS = {
  superadmin: "aissatou@my-omeo.app",
  content: "fatou@my-omeo.app",
  contentModeration: "ibrahim@my-omeo.app",
  support: "paul@my-omeo.app",
  finance: "nadege@my-omeo.app",
  moderation: "mariam@my-omeo.app",
  enrollment: "nouveau@my-omeo.app",
} as const;

export const PASSWORD = "omeo-demo-2026";
export const TOTP = "000000";

/** Connexion complète : email, mot de passe, puis second facteur. */
export async function login(page: Page, email: string, next = "/") {
  await page.goto(`/login${next === "/" ? "" : `?next=${encodeURIComponent(next)}`}`);
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Mot de passe").fill(PASSWORD);
  await page.getByRole("button", { name: "Continuer" }).click();
  await expect(page.getByRole("heading", { name: "Double authentification" })).toBeVisible();
  await page.getByLabel("Code").fill(TOTP);
  await page.getByRole("button", { name: "Vérifier" }).click();
  await expect(page.locator("aside.side")).toBeVisible();
}

/** Accessibilité (axe) : aucune violation sérieuse ou critique. */
export async function expectAccessible(page: Page) {
  const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
  const serious = results.violations.filter((v) => v.impact === "serious" || v.impact === "critical");
  expect(serious.map((v) => `${v.id}: ${v.nodes.map((n) => n.target.join(" ")).join(", ")}`)).toEqual([]);
}

/** Step-up : saisit le code dans la fenêtre si elle apparaît. */
export async function confirmStepUp(page: Page) {
  const dialog = page.getByRole("dialog", { name: "Confirme ton identité" });
  await expect(dialog).toBeVisible();
  await dialog.getByLabel("Code").fill(TOTP);
  await dialog.getByRole("button", { name: "Confirmer et continuer" }).click();
  await expect(dialog).toBeHidden();
}
