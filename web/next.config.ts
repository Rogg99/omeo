import type { NextConfig } from "next";
import { PHASE_PRODUCTION_BUILD } from "next/constants";
import createNextIntlPlugin from "next-intl/plugin";

/**
 * Source de données choisie au build : seule l'implémentation retenue est embarquée.
 * En production (`next build`), le mode mock est refusé : le dossier mock n'est jamais livré.
 */
const DATA_SOURCES = {
  api: "./src/server/data/api/index.ts",
  mock: "./src/server/data/mock/index.ts",
} as const;

function dataSource(phase: string): keyof typeof DATA_SOURCES {
  const value = process.env.DATA_SOURCE ?? "api";
  if (value !== "api" && value !== "mock") {
    throw new Error(`DATA_SOURCE doit valoir "api" ou "mock" (reçu : "${value}").`);
  }
  if (value === "mock" && phase === PHASE_PRODUCTION_BUILD) {
    throw new Error("DATA_SOURCE=mock est interdit pour un build de production. Utilise DATA_SOURCE=api.");
  }
  return value;
}

/** En-têtes de sécurité statiques. La CSP (avec nonce) est posée par src/proxy.ts. */
const SECURITY_HEADERS = [
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=(), browsing-topics=()",
  },
];

const withNextIntl = createNextIntlPlugin("./src/i18n/request.ts");

export default function config(phase: string): NextConfig {
  const source = DATA_SOURCES[dataSource(phase)];
  return withNextIntl({
    cacheComponents: true,
    partialPrefetching: true,
    output: "standalone",
    poweredByHeader: false,
    // Accès en dev via le proxy nginx
    allowedDevOrigins: ["localhost", "admin.localhost"],
    images: {
      formats: ["image/avif", "image/webp"],
      deviceSizes: [360, 480, 640, 828, 1080, 1280, 1920],
      minimumCacheTTL: 2_592_000,
    },
    cacheLife: {
      // Contenus publiés depuis l'admin : FAQ, pages légales, tarifs
      content: { stale: 300, revalidate: 600, expire: 86_400 },
    },
    async headers() {
      return [{ source: "/:path*", headers: SECURITY_HEADERS }];
    },
    turbopack: {
      resolveAlias: { "@/server/data/source": source },
      rules: {
        "*.css": {
          loaders: ["@tailwindcss/turbopack"],
          as: "*.css",
        },
      },
    },
  });
}
