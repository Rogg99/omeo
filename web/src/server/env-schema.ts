/**
 * Lecture de la configuration, sans marqueur server-only : importée aussi par src/proxy.ts
 * (qui n'est pas compilé avec la condition react-server). Les composants passent par ./env.
 */

import { z } from "zod";

/**
 * Configuration serveur, validée au démarrage. Aucune de ces valeurs n'est envoyée au navigateur
 * (pas de NEXT_PUBLIC_*). Chaque variable est documentée dans .env.example.
 */
const optional = z
  .string()
  .trim()
  .transform((v) => (v === "" ? undefined : v))
  .optional();

const schema = z
  .object({
    NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
    DATA_SOURCE: z.enum(["api", "mock"]).default("api"),
    SITE_URL: z.url().default("http://localhost"),
    API_URL_INTERNAL: optional.pipe(z.url().optional()),
    REVALIDATE_SECRET: optional.pipe(z.string().min(32).optional()),
    TURNSTILE_SITE_KEY: optional,
    PAYMENT_ORIGINS: z
      .string()
      .default("")
      .transform((v) =>
        v
          .split(",")
          .map((o) => o.trim())
          .filter(Boolean),
      )
      .pipe(z.array(z.url())),
    GOOGLE_CLIENT_ID: optional,
    GOOGLE_CLIENT_SECRET: optional,
    APPLE_SERVICE_ID: optional,
    APPLE_TEAM_ID: optional,
    APPLE_KEY_ID: optional,
    APPLE_PRIVATE_KEY: optional,
    ANDROID_PACKAGE: z.string().default("app.omeo"),
    IOS_APP_ID: z.string().regex(/^\d+$/).default("6740000000"),
    ANALYTICS_PROVIDER: z.enum(["none", "plausible", "umami"]).default("none"),
    ANALYTICS_SCRIPT_URL: optional.pipe(z.url().optional()),
    ANALYTICS_EVENT_URL: optional.pipe(z.url().optional()),
    ANALYTICS_SITE_ID: optional,
    MOCK_LATENCY_MS: z.coerce.number().int().min(0).max(10_000).default(300),
  })
  .superRefine((env, ctx) => {
    if (env.DATA_SOURCE === "api") {
      for (const key of ["API_URL_INTERNAL", "REVALIDATE_SECRET", "TURNSTILE_SITE_KEY"] as const) {
        if (!env[key]) ctx.addIssue({ code: "custom", path: [key], message: "requis quand DATA_SOURCE=api" });
      }
    }
    if (env.DATA_SOURCE === "mock" && env.NODE_ENV === "production") {
      ctx.addIssue({ code: "custom", path: ["DATA_SOURCE"], message: "le mode mock est interdit en production" });
    }
    if (env.ANALYTICS_PROVIDER !== "none" && (!env.ANALYTICS_SCRIPT_URL || !env.ANALYTICS_EVENT_URL)) {
      ctx.addIssue({ code: "custom", path: ["ANALYTICS_SCRIPT_URL"], message: "requis avec ANALYTICS_PROVIDER" });
    }
  });

export type Env = z.infer<typeof schema>;

function load(): Env {
  const parsed = schema.safeParse(process.env);
  if (!parsed.success) {
    const details = parsed.error.issues.map((i) => `  ${i.path.join(".")} : ${i.message}`).join("\n");
    throw new Error(`Configuration invalide :\n${details}`);
  }
  return parsed.data;
}

export const env: Env = load();

export const siteOrigin = new URL(env.SITE_URL).origin;
export const isSecureSite = siteOrigin.startsWith("https://");

export const googleSignInEnabled = Boolean(env.GOOGLE_CLIENT_ID && env.GOOGLE_CLIENT_SECRET);
export const appleSignInEnabled = Boolean(
  env.APPLE_SERVICE_ID && env.APPLE_TEAM_ID && env.APPLE_KEY_ID && env.APPLE_PRIVATE_KEY,
);
