import { readFile } from "node:fs/promises";
import { join } from "node:path";

import type { Locale } from "@/i18n/routing";

/**
 * Images Open Graph (next/og). Satori ne lit pas les variables CSS : ces valeurs reprennent les
 * tokens (shared/tokens/base.json) — sage.800, ink.950, cream.50, orange.500, sage.100.
 */
export const OG_COLORS = { brand: "#33422f", ink: "#151411", cream: "#fbf8f2", accent: "#e2742b", soft: "#e2e8da" } as const;

export const OG_SIZE = { width: 1200, height: 630 };

/** Langues dont les glyphes ne sont pas dans la police embarquée : le texte de l'image passe en anglais. */
const LATIN_ONLY: ReadonlySet<Locale> = new Set(["ar", "zh", "ja"]);

export function ogLocale(locale: Locale): Locale {
  return LATIN_ONLY.has(locale) ? "en" : locale;
}

export async function ogFonts() {
  const dir = join(process.cwd(), "node_modules/@fontsource/space-grotesk/files");
  const data = await readFile(join(dir, "space-grotesk-latin-600-normal.woff"));
  return [{ name: "Space Grotesk", data, weight: 600 as const, style: "normal" as const }];
}

/** Logo Omeo (disque entamé) pour les images. */
export function OgLogo({ color }: { color: string }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
      <svg width="64" height="64" viewBox="0 0 64 64">
        <path d="M55.98 32.98A24 24 0 1 1 41.12 9.8A8.5 8.5 0 0 0 50.21 21.41A7 7 0 0 0 55.98 32.98Z" fill={color} />
      </svg>
      <span style={{ fontSize: 48, color }}>omeo</span>
    </div>
  );
}
