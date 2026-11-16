/**
 * Adresse IP de la personne connectée, transmise à l'API (X-Forwarded-For) pour l'audit et la
 * limitation de débit. nginx pose X-Real-IP ($remote_addr) et ajoute le client à la fin de
 * X-Forwarded-For : les premières adresses de cette chaîne peuvent être falsifiées par le client.
 * Sans marqueur server-only : utilisé aussi par src/proxy.ts.
 */
export function clientIpFrom(h: Headers): string | undefined {
  const real = h.get("x-real-ip")?.trim();
  if (real) return real;
  const last = h.get("x-forwarded-for")?.split(",").at(-1)?.trim();
  return last || undefined;
}
