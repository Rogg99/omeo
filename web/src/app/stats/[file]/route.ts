import type { NextRequest } from "next/server";

import { env } from "@/server/env";
import { clientIpFrom } from "@/server/request";

/**
 * Mesure d'audience servie depuis le domaine du site (Plausible ou Umami) : aucun script tiers,
 * aucune requête vers un autre domaine. Le script n'est chargé qu'après consentement.
 *   GET  /stats/script.js → script du fournisseur
 *   POST /stats/event     → événement relayé au fournisseur
 */
export async function GET(_request: NextRequest, { params }: { params: Promise<{ file: string }> }) {
  const { file } = await params;
  if (file !== "script.js" || env.ANALYTICS_PROVIDER === "none" || !env.ANALYTICS_SCRIPT_URL) return new Response(null, { status: 404 });
  const upstream = await fetch(env.ANALYTICS_SCRIPT_URL, { next: { revalidate: 86_400 } }).catch(() => undefined);
  if (!upstream?.ok) return new Response(null, { status: 502 });
  return new Response(upstream.body, {
    headers: { "content-type": "application/javascript; charset=utf-8", "cache-control": "public, max-age=86400" },
  });
}

export async function POST(request: NextRequest, { params }: { params: Promise<{ file: string }> }) {
  const { file } = await params;
  if (file !== "event" || env.ANALYTICS_PROVIDER === "none" || !env.ANALYTICS_EVENT_URL) return new Response(null, { status: 404 });
  const raw = await request.text();
  if (raw.length > 4_096) return new Response(null, { status: 413 });
  const headers = new Headers({ "content-type": "application/json" });
  const ua = request.headers.get("user-agent");
  const ip = clientIpFrom(request.headers);
  if (ua) headers.set("user-agent", ua);
  if (ip) headers.set("x-forwarded-for", ip);
  const upstream = await fetch(env.ANALYTICS_EVENT_URL, { method: "POST", headers, body: raw }).catch(() => undefined);
  return new Response(null, { status: upstream?.ok ? 202 : 502 });
}
