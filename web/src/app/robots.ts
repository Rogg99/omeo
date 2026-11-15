import type { MetadataRoute } from "next";

import source from "@/server/data/source";
import { siteOrigin } from "@/server/env";

export default function robots(): MetadataRoute.Robots {
  // Démonstration : rien n'est indexé.
  if (source.demo) return { rules: [{ userAgent: "*", disallow: "/" }] };
  return {
    rules: [{ userAgent: "*", allow: "/", disallow: ["/api/", "/auth/", "/session/", "/hooks/", "/stats/", "/*/subscription", "/*/delete-account/confirm"] }],
    sitemap: `${siteOrigin}/sitemap.xml`,
    host: siteOrigin,
  };
}
