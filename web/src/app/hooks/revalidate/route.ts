import { revalidateTag } from "next/cache";
import { z } from "zod";

import { ALL_CACHE_TAGS, type CacheTag } from "@/server/data/cache-tags";
import { env } from "@/server/env";
import { verifySignature } from "@/server/revalidate-signature";

/**
 * Webhook de revalidation, appelé par l'API à la publication d'un contenu (FAQ, page légale, tarifs).
 *
 * En-têtes : X-Omeo-Timestamp (secondes epoch) et X-Omeo-Signature (`sha256=<hex>`, HMAC-SHA256 de
 * `${timestamp}.${corps brut}` avec REVALIDATE_SECRET). Corps : `{ "tags": ["faq", "legal"] }`.
 * Une signature de plus de 5 minutes est refusée (rejeu).
 */
const payload = z.object({ tags: z.array(z.enum(ALL_CACHE_TAGS as [CacheTag, ...CacheTag[]])).min(1) });

export async function POST(request: Request) {
  const secret = env.REVALIDATE_SECRET;
  if (!secret) return new Response(null, { status: 404 });
  const raw = await request.text();
  const valid = verifySignature(
    secret,
    request.headers.get("x-omeo-timestamp"),
    request.headers.get("x-omeo-signature"),
    raw,
    Math.floor(Date.now() / 1000),
  );
  if (!valid) return new Response(null, { status: 401 });

  let parsed;
  try {
    parsed = payload.safeParse(JSON.parse(raw));
  } catch {
    return new Response(null, { status: 400 });
  }
  if (!parsed.success) return new Response(null, { status: 400 });

  for (const tag of parsed.data.tags) revalidateTag(tag, "max");
  return Response.json({ revalidated: parsed.data.tags });
}
