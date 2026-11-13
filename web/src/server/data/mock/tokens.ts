import { randomBytes } from "node:crypto";

import type { Tokens } from "../types";

/** Préfixe des jetons simulés. Sert aussi de marqueur : la CI vérifie qu'il est absent du build de production. */
export const MOCK_MARKER = "omeo-mock-data-source";

const ACCESS_TTL_MS = 15 * 60 * 1000;
const REFRESH_TTL_MS = 30 * 24 * 60 * 60 * 1000;

type Claims = { sid: string; typ: "access" | "refresh"; exp: number; jti: string };

function encode(claims: Claims): string {
  return `${MOCK_MARKER}.${Buffer.from(JSON.stringify(claims)).toString("base64url")}`;
}

export function decode(token: string, typ: Claims["typ"], now = Date.now()): Claims | undefined {
  const [prefix, payload] = token.split(".");
  if (prefix !== MOCK_MARKER || !payload) return undefined;
  try {
    const claims = JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as Claims;
    return claims.typ === typ && claims.exp > now ? claims : undefined;
  } catch {
    return undefined;
  }
}

export function issue(sid: string, now = Date.now()): Tokens {
  const jti = () => randomBytes(8).toString("hex");
  const accessExp = now + ACCESS_TTL_MS;
  return {
    access: encode({ sid, typ: "access", exp: accessExp, jti: jti() }),
    refresh: encode({ sid, typ: "refresh", exp: now + REFRESH_TTL_MS, jti: jti() }),
    access_expires_at: new Date(accessExp).toISOString(),
  };
}
