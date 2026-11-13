/**
 * Client typé de l'API Omeo, généré depuis contracts/openapi.yaml.
 *
 * - `schema.d.ts` est produit par `pnpm gen:api` : ne jamais le modifier à la main.
 * - Les URL passent par `apiUrl` : appel direct sur le réseau interne côté serveur,
 *   proxy /api/... côté navigateur. L'adresse réelle de l'API n'est jamais exposée.
 */
import createClient from "openapi-fetch";

import { apiUrl } from "./http";
import type { components, paths } from "./schema";

export const api = createClient<paths>({ baseUrl: apiUrl("v1") });

export type Schemas = components["schemas"];
export { apiFetch, apiUrl } from "./http";
