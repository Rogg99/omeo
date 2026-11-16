import { NextResponse, type NextRequest } from "next/server";

import { adminOrigin } from "@/server/env";
import { ensureSession } from "@/server/session";
import { safeNextPath } from "@/server/session-cookies";

/**
 * Renouvellement transparent du jeton d'accès (appelé par src/proxy.ts avant le rendu d'une page) :
 * rotation côté serveur, puis retour à la page demandée. Échec → connexion.
 */
export async function GET(request: NextRequest) {
  const next = safeNextPath(request.nextUrl.searchParams.get("next"));
  const session = await ensureSession();
  const target = session ? new URL(next, adminOrigin) : new URL(`/login?next=${encodeURIComponent(next)}`, adminOrigin);
  return NextResponse.redirect(target, 303);
}
