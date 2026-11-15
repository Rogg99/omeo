/**
 * Limitation de débit en mémoire, par fenêtre fixe. Suffisante pour une instance unique du site ;
 * l'API applique de son côté sa propre limitation, qui fait foi.
 */
type Bucket = { count: number; resetAt: number };

const globalBuckets = globalThis as typeof globalThis & { __omeoRateLimit?: Map<string, Bucket> };
const buckets = (globalBuckets.__omeoRateLimit ??= new Map());

export type RateLimitRule = { limit: number; windowMs: number };

export const RATE_LIMITS = {
  /** Proxy /api : appels des îlots client. */
  api: { limit: 60, windowMs: 60_000 },
  /** Connexion par mot de passe. */
  login: { limit: 10, windowMs: 10 * 60_000 },
  /** Formulaires publics (contact, suppression de compte). */
  form: { limit: 5, windowMs: 10 * 60_000 },
} satisfies Record<string, RateLimitRule>;

export type RateLimitResult = { ok: true } | { ok: false; retryAfterSeconds: number };

export function hit(key: string, rule: RateLimitRule, now = Date.now()): RateLimitResult {
  const bucket = buckets.get(key);
  if (!bucket || bucket.resetAt <= now) {
    buckets.set(key, { count: 1, resetAt: now + rule.windowMs });
    if (buckets.size > 10_000) sweep(now);
    return { ok: true };
  }
  bucket.count += 1;
  if (bucket.count > rule.limit) return { ok: false, retryAfterSeconds: Math.ceil((bucket.resetAt - now) / 1000) };
  return { ok: true };
}

function sweep(now: number): void {
  for (const [key, bucket] of buckets) if (bucket.resetAt <= now) buckets.delete(key);
}

/** Réservé aux tests. */
export function resetRateLimits(): void {
  buckets.clear();
}
