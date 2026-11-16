/**
 * Lecture des filtres d'URL (searchParams des pages). Toute valeur inconnue est ignorée : l'URL est
 * une entrée non fiable, l'API revalide de toute façon.
 */
export type RawParams = Record<string, string | string[] | undefined>;

export function str(params: RawParams, key: string, max = 200): string | undefined {
  const v = params[key];
  const value = typeof v === "string" ? v.trim() : undefined;
  return value ? value.slice(0, max) : undefined;
}

export function oneOf<T extends string>(params: RawParams, key: string, allowed: readonly T[]): T | undefined {
  const v = str(params, key);
  return v !== undefined && (allowed as readonly string[]).includes(v) ? (v as T) : undefined;
}

export function int(params: RawParams, key: string, { min = 1, max = 10_000 } = {}): number | undefined {
  const v = Number(str(params, key));
  return Number.isInteger(v) && v >= min && v <= max ? v : undefined;
}

export function num(params: RawParams, key: string, { min = 0, max = 1 } = {}): number | undefined {
  const raw = str(params, key);
  if (raw === undefined) return undefined;
  const v = Number(raw);
  return Number.isFinite(v) && v >= min && v <= max ? v : undefined;
}

/** Tri « champ » ou « -champ » limité aux champs permis. */
export function ordering(params: RawParams, allowed: readonly string[]): string | undefined {
  const v = str(params, "ordering");
  return v && allowed.includes(v.replace(/^-/, "")) ? v : undefined;
}

export function isoDate(params: RawParams, key: string): string | undefined {
  const v = str(params, key);
  return v && /^\d{4}-\d{2}-\d{2}$/.test(v) ? v : undefined;
}

/** Pagination standard des listes de l'admin. */
export const PAGE_SIZE = 25;
export function pageOf(params: RawParams): { page: number; page_size: number } {
  return { page: int(params, "page") ?? 1, page_size: PAGE_SIZE };
}
