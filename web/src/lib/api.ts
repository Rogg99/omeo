/**
 * Client de l'API Omeo.
 *
 * - Côté serveur (Server Components, Server Actions) : appel direct à l'API sur le réseau interne.
 * - Côté navigateur : appel à /api/... sur ce domaine, relayé par app/api/[...path]/route.ts.
 * Dans les deux cas, l'adresse réelle de l'API n'est jamais visible par le client.
 */
export function apiUrl(path: string): string {
  const clean = path.replace(/^\/+/, "");
  if (typeof window === "undefined") {
    return `${process.env.API_URL_INTERNAL}/api/${clean}`;
  }
  return `/api/${clean}`;
}

export function apiFetch(path: string, init?: RequestInit): Promise<Response> {
  return fetch(apiUrl(path), init);
}
