import { ImageResponse } from "next/og";
import { getTranslations } from "next-intl/server";

import { DEFAULT_LOCALE, isLocale } from "@/i18n/routing";
import { OG_COLORS, OG_SIZE, OgLogo, ogFonts, ogLocale } from "@/lib/og";

import { loadInvite } from "./invite";

export const size = OG_SIZE;
export const contentType = "image/png";
export const alt = "Omeo";

/** Aperçu personnalisé d'une invitation : « Awa t'offre 7 jours de Plus ». */
export default async function InviteImage({ params }: { params: Promise<{ locale: string; code: string }> }) {
  const { locale: raw, code } = await params;
  const pageLocale = isLocale(raw) ? raw : DEFAULT_LOCALE;
  const locale = ogLocale(pageLocale);
  const [t, invite] = await Promise.all([getTranslations({ locale, namespace: "web" }), loadInvite(code, pageLocale)]);
  const check = invite?.check?.valid ? invite.check : undefined;
  const title = check?.referrer_first_name
    ? t("invite.title", { firstName: check.referrer_first_name, days: check.trial_days })
    : t("meta.invite_title_generic");

  return new ImageResponse(
    (
      <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", justifyContent: "space-between", padding: 80, background: OG_COLORS.ink, color: OG_COLORS.cream, fontFamily: "Space Grotesk" }}>
        <OgLogo color={OG_COLORS.soft} />
        <div style={{ display: "flex", flexDirection: "column", gap: 28 }}>
          <div style={{ fontSize: 80, lineHeight: 1.05, letterSpacing: -2 }}>{title}</div>
          {check && invite ? (
            <div style={{ display: "flex", alignSelf: "flex-start", padding: "16px 28px", borderRadius: 24, background: OG_COLORS.accent, color: OG_COLORS.ink, fontSize: 40, letterSpacing: 4 }}>
              {invite.code}
            </div>
          ) : null}
        </div>
      </div>
    ),
    { ...OG_SIZE, fonts: await ogFonts() },
  );
}
