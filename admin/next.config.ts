import type { NextConfig } from "next";
import { PHASE_PRODUCTION_BUILD } from "next/constants";
import createNextIntlPlugin from "next-intl/plugin";

/**
 * Source de données choisie au build : seule l'implémentation retenue est embarquée.
 * `next build` refuse DATA_SOURCE=mock : les données simulées ne sont jamais livrées en production.
 */
const DATA_SOURCES = {
  api: "./src/server/data/api.ts",
  mock: "./src/server/data/mock.ts",
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

/** En-têtes de sécurité statiques. La CSP (avec nonce, frame-ancestors 'none') est posée par src/proxy.ts. */
const SECURITY_HEADERS = [
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" },
  { key: "Referrer-Policy", value: "no-referrer" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
  { key: "Cross-Origin-Resource-Policy", value: "same-origin" },
  { key: "X-Robots-Tag", value: "noindex, nofollow" },
  {
    key: "Permissions-Policy",
    value:
      "camera=(), microphone=(), geolocation=(), payment=(), usb=(), serial=(), bluetooth=(), interest-cohort=(), browsing-topics=()",
  },
];

const withNextIntl = createNextIntlPlugin("./src/i18n/request.ts");

export default function config(phase: string): NextConfig {
  const source = DATA_SOURCES[dataSource(phase)];
  return withNextIntl({
    output: "standalone",
    poweredByHeader: false,
    // Accès en dev via le proxy nginx
    allowedDevOrigins: ["localhost", "admin.localhost"],
    experimental: {
      // forbidden() : écran dédié aux refus (permission absente ou 403 forbidden_role de l'API)
      authInterrupts: true,
      serverActions: { bodySizeLimit: "1mb" },
    },
    async headers() {
      return [
        { source: "/:path*", headers: SECURITY_HEADERS },
        // Aucune page de l'admin ne doit rester dans un cache partagé ou dans l'historique.
        { source: "/((?!_next/static).*)", headers: [{ key: "Cache-Control", value: "private, no-store" }] },
      ];
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
