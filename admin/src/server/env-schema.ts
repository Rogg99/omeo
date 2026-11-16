/**
 * Configuration serveur de l'admin, validée au démarrage. Sans marqueur server-only : importée aussi
 * par src/proxy.ts. Les composants passent par ./env. Aucune valeur n'est envoyée au navigateur
 * (pas de NEXT_PUBLIC_*). Chaque variable est documentée dans .env.example.
 */
import { z } from "zod";

const optional = z
  .string()
  .trim()
  .transform((v) => (v === "" ? undefined : v))
  .optional();

const schema = z
  .object({
    NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
    DATA_SOURCE: z.enum(["api", "mock"]).default("api"),
    /** Adresse publique de l'admin : contrôle de l'en-tête Origin, cookies __Host- en HTTPS. */
    ADMIN_URL: z.url().default("http://admin.localhost"),
    API_URL_INTERNAL: optional.pipe(z.url().optional()),
    /** Préfixe des routes de l'API ; vide pour Prism, qui sert le contrat à la racine. */
    API_BASE_PATH: z
      .string()
      .regex(/^(\/[\w.-]+)*$/)
      .default("/api/v1"),
    /** Clé HMAC des cookies de session (durées d'inactivité et maximale) et du jeton CSRF. */
    SESSION_SECRET: optional.pipe(z.string().min(32).optional()),
    SESSION_IDLE_MINUTES: z.coerce.number().int().min(5).max(120).default(30),
    SESSION_MAX_HOURS: z.coerce.number().int().min(1).max(24).default(12),
    /**
     * Origines du stockage des médias (URL présignées de téléversement, images, vidéos), séparées par
     * des virgules. Autorisées par la CSP (connect-src, img-src, media-src).
     */
    MEDIA_ORIGINS: z
      .string()
      .default("")
      .transform((v) =>
        v
          .split(",")
          .map((o) => o.trim())
          .filter(Boolean),
      )
      .pipe(z.array(z.url())),
    MOCK_LATENCY_MS: z.coerce.number().int().min(0).max(10_000).default(300),
  })
  .superRefine((env, ctx) => {
    if (env.DATA_SOURCE === "api" && !env.API_URL_INTERNAL) {
      ctx.addIssue({ code: "custom", path: ["API_URL_INTERNAL"], message: "requis quand DATA_SOURCE=api" });
    }
    if (env.NODE_ENV === "production") {
      if (env.DATA_SOURCE === "mock") {
        ctx.addIssue({ code: "custom", path: ["DATA_SOURCE"], message: "le mode mock est interdit en production" });
      }
      if (!env.SESSION_SECRET) {
        ctx.addIssue({ code: "custom", path: ["SESSION_SECRET"], message: "requis en production" });
      }
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

export const adminOrigin = new URL(env.ADMIN_URL).origin;
/** HTTPS : cookies Secure avec le préfixe __Host-. */
export const isSecureAdmin = adminOrigin.startsWith("https://");

/**
 * Clé de signature des cookies. En développement et en test, une clé dérivée fixe évite d'exiger
 * un secret ; elle est refusée en production par le schéma ci-dessus.
 */
export const sessionSecret = env.SESSION_SECRET ?? "omeo-admin-dev-only-session-secret-not-for-prod";
