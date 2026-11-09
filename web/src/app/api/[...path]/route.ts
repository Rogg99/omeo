/**
 * Proxy vers l'API Nyam.
 *
 * Le navigateur n'appelle jamais l'API directement : il appelle /api/... sur ce
 * domaine, et le serveur Next relaie vers API_URL_INTERNAL (réseau Docker).
 * L'adresse de l'API n'est donc jamais envoyée au client.
 * Ne JAMAIS exposer cette adresse via une variable NEXT_PUBLIC_*.
 */
import type { NextRequest } from "next/server";

const API_URL = process.env.API_URL_INTERNAL;

// En-têtes à ne pas recopier entre les deux requêtes
const HOP_BY_HOP = ["host", "connection", "content-length", "transfer-encoding", "keep-alive", "upgrade"];

async function proxy(req: NextRequest, { params }: { params: Promise<{ path: string[] }> }) {
  if (!API_URL) {
    return Response.json({ detail: "API indisponible" }, { status: 502 });
  }
  const { path } = await params;
  const target = `${API_URL}/api/${path.join("/")}/${req.nextUrl.search}`.replace(/\/+(\?|$)/, "/$1");

  const headers = new Headers(req.headers);
  HOP_BY_HOP.forEach((h) => headers.delete(h));
  // Pour que Django génère des liens (pagination…) sur ce domaine et pas sur l'API
  headers.set("x-forwarded-host", req.headers.get("host") ?? "");
  headers.set("x-forwarded-proto", req.nextUrl.protocol.replace(":", ""));

  let upstream: Response;
  try {
    upstream = await fetch(target, {
      method: req.method,
      headers,
      body: ["GET", "HEAD"].includes(req.method) ? undefined : req.body,
      redirect: "manual",
      // @ts-expect-error requis par Node pour streamer le corps de la requête
      duplex: "half",
    });
  } catch {
    return Response.json({ detail: "API indisponible" }, { status: 502 });
  }

  const resHeaders = new Headers(upstream.headers);
  HOP_BY_HOP.forEach((h) => resHeaders.delete(h));
  resHeaders.delete("content-encoding"); // fetch a déjà décompressé le corps
  resHeaders.delete("server");
  return new Response(upstream.body, { status: upstream.status, headers: resHeaders });
}

export { proxy as GET, proxy as POST, proxy as PUT, proxy as PATCH, proxy as DELETE, proxy as OPTIONS };
