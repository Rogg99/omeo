import source from "@/server/data/source";

/**
 * Cible des URL présignées en mode mock : accepte le fichier sans le conserver. En production
 * (DATA_SOURCE=api), les URL pointent vers le stockage objet et cette route répond 404.
 */
const MAX_BYTES = 524_288_000;

export async function PUT(request: Request) {
  if (!source.demo) return new Response(null, { status: 404 });
  const size = Number(request.headers.get("content-length") ?? 0);
  if (size > MAX_BYTES) return new Response(null, { status: 413 });
  await request.arrayBuffer();
  return new Response(null, { status: 200 });
}
