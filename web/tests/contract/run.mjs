/**
 * Tests de contrat : build de production (DATA_SOURCE=api) servi contre Prism, qui valide chaque
 * requête du site contre contracts/openapi.yaml (--errors : 4xx sur toute requête non conforme).
 * Turnstile utilise la clé de test officielle de Cloudflare (toujours acceptée, vrai widget).
 *
 *   node tests/contract/run.mjs            (build puis tests)
 *   node tests/contract/run.mjs --no-build (réutilise .next)
 */
import { spawnSync } from "node:child_process";
import { cpSync, mkdirSync } from "node:fs";

const PORT = 3200;
export const CONTRACT_ENV = {
  NEXT_TELEMETRY_DISABLED: "1",
  DATA_SOURCE: "api",
  API_URL_INTERNAL: "http://127.0.0.1:4010",
  API_BASE_PATH: "",
  SITE_URL: `http://localhost:${PORT}`,
  REVALIDATE_SECRET: "contract-revalidate-secret-0123456789",
  // Clé publique de test Cloudflare : le widget passe toujours
  TURNSTILE_SITE_KEY: "1x00000000000000000000AA",
  // Identifiants factices : vérifient le flux OAuth jusqu'à la redirection vers le fournisseur
  GOOGLE_CLIENT_ID: "contract-test.apps.googleusercontent.com",
  GOOGLE_CLIENT_SECRET: "contract-test-secret",
  APPLE_SERVICE_ID: "app.omeo.contract",
  APPLE_TEAM_ID: "TEAM000000",
  APPLE_KEY_ID: "KEY0000000",
  APPLE_PRIVATE_KEY: "contract-test-key",
};

const run = (command, args, extraEnv = {}) => {
  const result = spawnSync(command, args, { stdio: "inherit", shell: process.platform === "win32", env: { ...process.env, ...CONTRACT_ENV, ...extraEnv } });
  if (result.status !== 0) process.exit(result.status ?? 1);
};

if (!process.argv.includes("--no-build")) {
  run("pnpm", ["next", "build"]);
  cpSync("public", ".next/standalone/public", { recursive: true });
  mkdirSync(".next/standalone/.next", { recursive: true });
  cpSync(".next/static", ".next/standalone/.next/static", { recursive: true });
}
run("pnpm", ["exec", "playwright", "test", "-c", "playwright.contract.config.ts", ...process.argv.slice(2).filter((a) => a !== "--no-build")]);
