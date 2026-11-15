import { createHmac, timingSafeEqual } from "node:crypto";

/** Écart maximal accepté entre l'horodatage signé et l'heure du serveur (rejeu). */
const MAX_SKEW_S = 300;

export function sign(secret: string, timestamp: string, raw: string): string {
  return `sha256=${createHmac("sha256", secret).update(`${timestamp}.${raw}`).digest("hex")}`;
}

export function verifySignature(secret: string, timestamp: string | null, signature: string | null, raw: string, nowS: number): boolean {
  if (!timestamp || !signature || !/^\d+$/.test(timestamp)) return false;
  if (Math.abs(nowS - Number(timestamp)) > MAX_SKEW_S) return false;
  const expected = Buffer.from(sign(secret, timestamp, raw));
  const received = Buffer.from(signature);
  return expected.length === received.length && timingSafeEqual(expected, received);
}
