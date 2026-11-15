/**
 * Noms des cookies de session de la page Abonnement. Sans marqueur server-only : lu aussi par
 * src/proxy.ts pour décider d'un renouvellement avant le rendu.
 */
export const SESSION_COOKIES = {
  access: "omeo_at",
  refresh: "omeo_rt",
  /** Échéance du jeton d'accès (ms epoch), pour décider d'un renouvellement sans décoder le jeton. */
  expires: "omeo_exp",
  /** Email du compte (affiché sur la page Abonnement), reçu à la connexion. */
  email: "omeo_email",
} as const;

/** Marge avant échéance : un jeton qui expire dans moins de 30 s est déjà considéré comme expiré. */
export const EXPIRY_MARGIN_MS = 30_000;

export function isAccessFresh(expires: string | undefined, now = Date.now()): boolean {
  const at = Number(expires);
  return expires !== undefined && Number.isFinite(at) && at - EXPIRY_MARGIN_MS > now;
}

/** Une destination de redirection n'est acceptée que si elle reste sur le site. */
export function safeNextPath(next: string | null | undefined, fallback: string): string {
  if (!next || !next.startsWith("/") || next.startsWith("//") || next.includes("\\")) return fallback;
  return next;
}
