/**
 * Différence avant / après pour l'affichage (validations à quatre yeux, journal d'audit). Les objets
 * sont aplatis en chemins (`nutrition.min_kcal.female`) ; seules les valeurs qui changent sont gardées.
 */
export type DiffLine = { path: string; before: string | null; after: string | null };

type Json = unknown;

function flatten(value: Json, prefix = "", out: Record<string, string> = {}): Record<string, string> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    const entries = Object.entries(value as Record<string, Json>);
    if (entries.length === 0 && prefix) out[prefix] = "{}";
    for (const [k, v] of entries) flatten(v, prefix ? `${prefix}.${k}` : k, out);
  } else if (prefix) {
    out[prefix] = typeof value === "string" ? value : JSON.stringify(value);
  }
  return out;
}

export function diffObjects(before: Json, after: Json): DiffLine[] {
  const a = flatten(before ?? {});
  const b = flatten(after ?? {});
  const keys = [...new Set([...Object.keys(a), ...Object.keys(b)])].sort();
  return keys
    .filter((k) => a[k] !== b[k])
    .map((path) => ({ path, before: a[path] ?? null, after: b[path] ?? null }));
}

/**
 * Le `diff` d'une ApprovalRequest prend deux formes : `{ before, after }` (objet entier) ou
 * `{ champ: { before, after } }` (champ par champ). Les deux donnent la même liste de lignes.
 */
export function diffOfApproval(diff: Record<string, Json> | undefined): DiffLine[] {
  if (!diff) return [];
  if ("before" in diff || "after" in diff) return diffObjects(diff.before, diff.after);
  const before: Record<string, Json> = {};
  const after: Record<string, Json> = {};
  for (const [key, value] of Object.entries(diff)) {
    if (value && typeof value === "object" && ("before" in value || "after" in value)) {
      before[key] = (value as Record<string, Json>).before;
      after[key] = (value as Record<string, Json>).after;
    } else {
      after[key] = value;
    }
  }
  return diffObjects(before, after);
}
