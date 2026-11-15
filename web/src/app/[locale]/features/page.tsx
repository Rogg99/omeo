import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { Photo } from "@/components/Photo";
import { Link } from "@/i18n/navigation";
import { metadataLocale, pageLocale } from "@/i18n/page";
import { rich } from "@/i18n/rich";
import type { PhotoName } from "@/lib/photos";
import { pageMetadata } from "@/lib/seo";
import { siteOrigin } from "@/server/env";

export async function generateMetadata({ params }: PageProps<"/[locale]/features">): Promise<Metadata> {
  const locale = await metadataLocale(params);
  if (!locale) return {};
  const t = await getTranslations({ locale, namespace: "web.meta" });
  return pageMetadata({ origin: siteOrigin, locale, path: "/features", title: t("features_title"), description: t("features_description") });
}

const SECTIONS: { key: "photo" | "tracking" | "sport" | "programs" | "content"; photo: PhotoName }[] = [
  { key: "photo", photo: "thieb" },
  { key: "tracking", photo: "fonio" },
  { key: "sport", photo: "sport" },
  { key: "programs", photo: "sport2" },
  { key: "content", photo: "ndole" },
];

export default async function FeaturesPage({ params }: PageProps<"/[locale]/features">) {
  await pageLocale(params);
  const t = await getTranslations("web.features");
  return (
    <>
      <header className="page-head wrap">
        <p className="eyebrow">{t("eyebrow")}</p>
        <h1 className="h1 mt16">{t.rich("title", rich)}</h1>
      </header>
      {SECTIONS.map(({ key, photo }, i) => (
        <section key={key} className={`section tight${i % 2 === 1 ? " soft" : ""}`} aria-labelledby={`feat-${key}`}>
          <div className="wrap grid g2" style={{ alignItems: "center", gap: "var(--space-12)" }}>
            <div style={{ order: i % 2 === 1 ? 2 : 0 }}>
              <p className="eyebrow">{t(`${key}_name`)}</p>
              <h2 id={`feat-${key}`} className="h2 mt16">
                {t.rich(`${key}_title`, rich)}
              </h2>
              <p className="lead mt16">{t(`${key}_body`)}</p>
              <ul className="stack mt24" style={{ listStyle: "none", padding: 0 }}>
                {([1, 2, 3, 4] as const).map((n) => (
                  <li key={n} className="row" style={{ alignItems: "flex-start" }}>
                    <span style={{ color: "var(--primary-text)" }}>
                      <Icon name="check" />
                    </span>
                    <span>{t(`${key}_item${n}`)}</span>
                  </li>
                ))}
              </ul>
            </div>
            <Photo name={photo} alt={t(`${key}_alt`)} height={420} sizes="(max-width: 900px) 100vw, 560px" priority={i === 0} radius="var(--r-xl)" />
          </div>
        </section>
      ))}
      <section className="section tight">
        <div className="wrap">
          <div className="card brand center" style={{ padding: "var(--space-12)" }}>
            <h2 className="h2">{t("cta_title")}</h2>
            <p className="lead mt16" style={{ color: "var(--sage-100)" }}>
              {t("cta_lead")}
            </p>
            <Link className="btn light mt32" href="/#download">
              {t("cta_button")}
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}
