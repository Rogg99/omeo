import type { MetadataRoute } from "next";

import { LOCALES } from "@/i18n/routing";
import { languageAlternates, localizedUrl } from "@/lib/seo";
import source from "@/server/data/source";
import { siteOrigin } from "@/server/env";

/** Pages publiques indexables (l'abonnement, l'invitation et la confirmation de suppression en sont exclus). */
const PAGES: { path: string; priority: number; changeFrequency: "weekly" | "monthly" }[] = [
  { path: "/", priority: 1, changeFrequency: "weekly" },
  { path: "/features", priority: 0.8, changeFrequency: "monthly" },
  { path: "/pricing", priority: 0.9, changeFrequency: "weekly" },
  { path: "/faq", priority: 0.7, changeFrequency: "weekly" },
  { path: "/contact", priority: 0.5, changeFrequency: "monthly" },
  { path: "/delete-account", priority: 0.3, changeFrequency: "monthly" },
  { path: "/legal/terms", priority: 0.3, changeFrequency: "monthly" },
  { path: "/legal/privacy", priority: 0.3, changeFrequency: "monthly" },
  { path: "/legal/cookies", priority: 0.2, changeFrequency: "monthly" },
  { path: "/legal/legal_notice", priority: 0.2, changeFrequency: "monthly" },
  { path: "/credits", priority: 0.1, changeFrequency: "monthly" },
];

export default function sitemap(): MetadataRoute.Sitemap {
  if (source.demo) return [];
  return PAGES.flatMap(({ path, priority, changeFrequency }) =>
    LOCALES.map((locale) => ({
      url: localizedUrl(siteOrigin, locale, path),
      changeFrequency,
      priority,
      alternates: { languages: languageAlternates(siteOrigin, path) },
    })),
  );
}
