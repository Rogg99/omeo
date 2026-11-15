import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

/** Aucune violation WCAG 2.1 AA détectée par axe sur les pages publiques (clair, sombre, RTL). */
const PAGES = ["/fr", "/fr/features", "/fr/pricing", "/fr/faq", "/fr/contact", "/fr/legal/terms", "/fr/delete-account", "/fr/i/AWA2026", "/fr/subscription/login", "/ar", "/en/pricing"];

for (const path of PAGES) {
  test(`axe ${path} @mobile`, async ({ page }) => {
    await page.goto(path);
    const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"]).analyze();
    expect(results.violations.map((v) => `${v.id}: ${v.nodes.map((n) => n.target.join(" ")).join(", ")}`)).toEqual([]);
  });
}

test("axe en thème sombre", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "dark" });
  await page.goto("/fr/pricing");
  const results = await new AxeBuilder({ page }).withTags(["wcag2aa"]).analyze();
  expect(results.violations.map((v) => v.id)).toEqual([]);
});

test("l'arabe s'affiche de droite à gauche", async ({ page }) => {
  await page.goto("/ar");
  await expect(page.locator("html")).toHaveAttribute("dir", "rtl");
  await expect(page.locator("html")).toHaveAttribute("lang", "ar");
});

test("pas de défilement horizontal à 320 px @mobile", async ({ page }) => {
  await page.setViewportSize({ width: 320, height: 700 });
  for (const path of ["/fr", "/fr/pricing", "/fr/subscription/login"]) {
    await page.goto(path);
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow, path).toBeLessThanOrEqual(0);
  }
});
