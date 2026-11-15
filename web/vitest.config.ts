import { fileURLToPath } from "node:url";

import { defineConfig } from "vitest/config";

const src = fileURLToPath(new URL("./src", import.meta.url));

/** Tests des helpers et de la couche de données simulée (sans navigateur ni serveur Next). */
export default defineConfig({
  resolve: {
    alias: [
      { find: "@/server/data/source", replacement: `${src}/server/data/mock/index.ts` },
      { find: /^@\/(.*)$/, replacement: `${src}/$1` },
      { find: "server-only", replacement: fileURLToPath(new URL("./tests/support/empty.ts", import.meta.url)) },
    ],
  },
  test: {
    environment: "node",
    // next-intl importe « next/navigation » sans extension : résolu par Vite plutôt que par Node.
    server: { deps: { inline: ["next-intl"] } },
    include: ["tests/unit/**/*.test.ts"],
    setupFiles: ["tests/support/setup.ts"],
    env: { DATA_SOURCE: "mock", NODE_ENV: "test", SITE_URL: "https://my-omeo.test", MOCK_LATENCY_MS: "0", ANDROID_PACKAGE: "app.omeo", IOS_APP_ID: "6740000000" },
  },
});
