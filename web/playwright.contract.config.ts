import { defineConfig, devices } from "@playwright/test";

/** Build de production branché sur Prism (voir tests/contract/run.mjs, qui fournit l'environnement). */
const PORT = 3200;

export default defineConfig({
  testDir: "tests/contract",
  timeout: 60_000,
  expect: { timeout: 15_000 },
  workers: 1,
  reporter: process.env.CI ? [["github"]] : "list",
  use: { baseURL: `http://localhost:${PORT}`, locale: "fr-FR", ...devices["Desktop Chrome"] },
  webServer: [
    {
      command: "pnpm exec prism mock ../contracts/openapi.yaml -p 4010 --errors",
      url: "http://127.0.0.1:4010/billing/plans",
      reuseExistingServer: false,
      timeout: 60_000,
      stdout: "pipe",
    },
    {
      command: "node .next/standalone/server.js",
      url: `http://localhost:${PORT}/fr`,
      reuseExistingServer: false,
      timeout: 60_000,
      env: { PORT: String(PORT), HOSTNAME: "127.0.0.1" },
    },
  ],
});
