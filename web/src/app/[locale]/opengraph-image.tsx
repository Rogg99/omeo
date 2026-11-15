import { ImageResponse } from "next/og";
import { getTranslations } from "next-intl/server";

import { DEFAULT_LOCALE, isLocale } from "@/i18n/routing";
import { OG_COLORS, OG_SIZE, OgLogo, ogFonts, ogLocale } from "@/lib/og";

export const size = OG_SIZE;
export const contentType = "image/png";
export const alt = "Omeo";

/** Image de partage par défaut de toutes les pages d'une langue. */
export default async function OpenGraphImage({ params }: { params: Promise<{ locale: string }> }) {
  const { locale: raw } = await params;
  const locale = ogLocale(isLocale(raw) ? raw : DEFAULT_LOCALE);
  const t = await getTranslations({ locale, namespace: "web" });
  return new ImageResponse(
    (
      <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", justifyContent: "space-between", padding: 80, background: OG_COLORS.brand, color: OG_COLORS.cream, fontFamily: "Space Grotesk" }}>
        <OgLogo color={OG_COLORS.soft} />
        <div style={{ display: "flex", flexDirection: "column", gap: 24 }}>
          <div style={{ fontSize: 88, lineHeight: 1, letterSpacing: -3 }}>{t("hero.title")}</div>
          <div style={{ fontSize: 36, color: OG_COLORS.soft }}>{t("meta.og_tagline")}</div>
        </div>
      </div>
    ),
    { ...OG_SIZE, fonts: await ogFonts() },
  );
}
