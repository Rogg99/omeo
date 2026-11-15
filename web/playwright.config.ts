import { defineConfig, devices } from "@playwright/test";

/**
 * Parcours de bout en bout sur le serveur de dev en mode mock (données simulées, paiement simulé).
 * PLAYWRIGHT_BASE_URL permet de viser un serveur déjà lancé (par exemple branché sur Prism).
 */
const port = Number(process.env.E2E_PORT ?? 3100);
const baseURL = process.env.PLAYWRIGHT_BASE_URL ?? `http://localhost:${port}`;

export default defineConfig({
  testDir: "tests/e2e",
  timeout: 60_000,
  expect: { timeout: 15_000 },
  fullyParallel: true,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : "list",
  use: { baseURL, trace: "retain-on-failure", locale: "fr-FR" },
  projects: [
    { name: "desktop", use: { ...devices["Desktop Chrome"] } },
    { name: "mobile", use: { ...devices["Pixel 7"] }, grep: /@mobile/ },
  ],
  webServer: process.env.PLAYWRIGHT_BASE_URL
    ? undefined
    : {
        command: `pnpm next dev -p ${port}`,
        url: `${baseURL}/fr`,
        reuseExistingServer: !process.env.CI,
        timeout: 180_000,
        env: { DATA_SOURCE: "mock", SITE_URL: baseURL, MOCK_LATENCY_MS: "0" },
      },
});
