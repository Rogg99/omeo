import type { Locale } from "@/i18n/routing";

import { en } from "./en";
import { fr } from "./fr";
import type { LocalizedContent } from "./types";

/**
 * Contenus par langue. Une langue absente suit le repli de l'API : anglais, puis français.
 */
const CONTENT: Partial<Record<Locale, LocalizedContent>> = { fr, en };

export function contentFor(locale: Locale): LocalizedContent {
  return CONTENT[locale] ?? en;
}
