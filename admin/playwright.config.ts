import { defineConfig, devices } from "@playwright/test";

/**
 * Parcours de bout en bout sur le serveur de dev en mode mock (comptes de démo, code 000000).
 * PLAYWRIGHT_BASE_URL permet de viser un serveur déjà lancé (branché sur Prism ou sur l'API réelle).
 */
const port = Number(process.env.E2E_PORT ?? 3101);
const baseURL = process.env.PLAYWRIGHT_BASE_URL ?? `http://localhost:${port}`;

export default defineConfig({
  testDir: "tests/e2e",
  timeout: 90_000,
  expect: { timeout: 20_000 },
  // L'état simulé est partagé par le processus : les parcours qui écrivent s'exécutent en série.
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : "list",
  use: { baseURL, trace: "retain-on-failure", locale: "fr-FR", ...devices["Desktop Chrome"] },
  webServer: process.env.PLAYWRIGHT_BASE_URL
    ? undefined
    : {
        command: `pnpm next dev -p ${port}`,
        url: `${baseURL}/login`,
        reuseExistingServer: !process.env.CI,
        timeout: 180_000,
        env: { DATA_SOURCE: "mock", ADMIN_URL: baseURL, MOCK_LATENCY_MS: "0" },
      },
});
