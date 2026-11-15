import type { Metadata } from "next";
import { headers } from "next/headers";
import { getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import type { IconName } from "@/components/icons/paths";
import { QrCode } from "@/components/QrCode";
import { StoreButtons } from "@/components/StoreButtons";
import { metadataLocale, pageLocale } from "@/i18n/page";
import { rich } from "@/i18n/rich";
import { pageMetadata } from "@/lib/seo";
import { siteOrigin } from "@/server/env";
import { appStoreUrl, platformOf, playStoreUrl } from "@/server/stores";

import { CopyCode } from "./CopyCode";
import { loadInvite } from "./invite";

export async function generateMetadata({ params }: PageProps<"/[locale]/i/[code]">): Promise<Metadata> {
  const locale = await metadataLocale(params);
  if (!locale) return {};
  const invite = await loadInvite((await params).code, locale);
  const t = await getTranslations({ locale, namespace: "web.meta" });
  const check = invite?.check?.valid ? invite.check : undefined;
  const title = check?.referrer_first_name ? t("invite_title", { firstName: check.referrer_first_name }) : t("invite_title_generic");
  return {
    ...pageMetadata({
      origin: siteOrigin,
      locale,
      path: `/i/${invite?.code ?? (await params).code}`,
      title,
      description: t("invite_description", { days: check?.trial_days ?? 3 }),
      absoluteTitle: true,
    }),
    // Lien personnel : partagé, mais pas indexé
    robots: { index: false, follow: true },
  };
}

/**
 * Invitation /i/{code} : vérifie le code, puis renvoie vers le bon store en le conservant
 * (Play Install Referrer sur Android, copie du code sur iPhone).
 */
export default async function InvitePage({ params }: PageProps<"/[locale]/i/[code]">) {
  const locale = await pageLocale(params);
  const [t, tw, invite, h] = await Promise.all([getTranslations("web.invite"), getTranslations("web"), loadInvite((await params).code, locale), headers()]);
  const platform = platformOf(h.get("user-agent"));
  const check = invite?.check?.valid ? invite.check : undefined;
  const code = check ? invite?.code : undefined;
  const days = check?.trial_days ?? 3;
  // Téléphone reconnu : le bon store en premier (le code suit le lien Google Play).
  const primaryStore = platform === "android" ? playStoreUrl(code) : platform === "ios" ? appStoreUrl() : undefined;

  const reasons: [IconName, "why1" | "why2" | "why3"][] = [
    ["camera", "why1"],
    ["footprints", "why2"],
    ["book", "why3"],
  ];

  return (
    <div className="narrow" style={{ paddingBlock: "var(--space-16) var(--section)" }}>
      <div className="card brand" style={{ padding: "clamp(var(--space-6), 5vw, var(--space-12))" }}>
        <span className="ib glass">
          <Icon name="gift" />
        </span>
        {check ? (
          <>
            <h1 className="h2 mt24">
              {check.referrer_first_name
                ? t.rich("title_rich", { ...rich, accent: (c) => <span className="serif accent-on-brand">{c}</span>, firstName: check.referrer_first_name, days })
                : tw("meta.invite_title_generic")}
            </h1>
            <p className="lead mt16" style={{ color: "var(--sage-100)" }}>
              {t("lead", { days })}
            </p>
          </>
        ) : (
          <>
            <h1 className="h2 mt24">{t("invalid_title")}</h1>
            <p className="lead mt16" style={{ color: "var(--sage-100)" }}>
              {t("invalid_lead")}
            </p>
          </>
        )}

        {code ? (
          <div className="card mt32" style={{ color: "var(--text)", padding: "var(--space-5)" }}>
            <p className="small muted">{t("code_label")}</p>
            <div className="row wrapf mt8" style={{ justifyContent: "space-between" }}>
              <b style={{ font: "var(--weight-semibold) var(--text-2xl) var(--font-display)", letterSpacing: "0.08em" }} translate="no">
                {code}
              </b>
              <CopyCode code={code} copyLabel={t("copy")} copiedLabel={t("copied")} />
            </div>
            <p className="small muted mt16">{t("android_hint")}</p>
          </div>
        ) : null}

        <div className="mt32">
          {primaryStore ? (
            <a className="btn light block" href={primaryStore} data-store={platform}>
              <Icon name="phone" />
              {tw("nav.download")}
            </a>
          ) : null}
          <div className={`row wrapf${primaryStore ? " mt16" : ""}`} style={{ gap: "var(--space-6)" }}>
            <StoreButtons raised inviteCode={code} />
            {primaryStore ? null : (
              <div className="hide-m">
                <QrCode />
              </div>
            )}
          </div>
        </div>
      </div>

      <ul className="grid g3 mt32" style={{ listStyle: "none", padding: 0 }}>
        {reasons.map(([icon, key]) => (
          <li key={key} className="card">
            <span className="ib">
              <Icon name={icon} />
            </span>
            <h2 className="h3 mt16">{t(`${key}_title`)}</h2>
            <p className="muted mt8">{t(`${key}_body`)}</p>
          </li>
        ))}
      </ul>
    </div>
  );
}
