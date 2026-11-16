import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

/**
 * ESLint strict : règles Next (Core Web Vitals) + TypeScript, avec les garde-fous propres à l'admin.
 * - Le navigateur n'importe jamais le code serveur (couche de données, session, client de l'API).
 * - Les données simulées ne sont importées que par leur agrégateur (src/server/data/mock.ts).
 */
const MOCK_IMPORTS = {
  group: ["**/mock", "**/mock/**", "@/server/mock/**"],
  message: "Les données simulées passent uniquement par @/server/data/source.",
};

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  {
    rules: {
      "no-console": ["error", { allow: ["warn", "error"] }],
      eqeqeq: ["error", "always"],
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/consistent-type-imports": ["error", { fixStyle: "inline-type-imports" }],
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }],
      "react/jsx-no-target-blank": "error",
    },
  },
  {
    files: ["src/**"],
    ignores: ["src/server/data/mock.ts", "src/server/data/**/mock.ts", "src/server/mock/**"],
    rules: {
      "no-restricted-imports": ["error", { patterns: [MOCK_IMPORTS] }],
    },
  },
  {
    files: ["src/components/**", "src/hooks/**", "src/lib/**"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            MOCK_IMPORTS,
            { group: ["@/server/*", "server-only"], message: "Code serveur interdit dans les composants partagés." },
          ],
        },
      ],
    },
  },
  { files: ["scripts/**", "tests/**"], rules: { "no-console": "off" } },
  globalIgnores([".next/**", "out/**", "build/**", "next-env.d.ts", "src/lib/api/schema.d.ts", "playwright-report/**", "test-results/**"]),
]);

export default eslintConfig;
