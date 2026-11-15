import type { Metadata } from "next";
import Image from "next/image";
import { getTranslations } from "next-intl/server";

import { metadataLocale, pageLocale } from "@/i18n/page";
import { PHOTOS } from "@/lib/photos";
import { pageMetadata } from "@/lib/seo";
import { siteOrigin } from "@/server/env";

export async function generateMetadata({ params }: PageProps<"/[locale]/credits">): Promise<Metadata> {
  const locale = await metadataLocale(params);
  if (!locale) return {};
  const t = await getTranslations({ locale, namespace: "web" });
  return pageMetadata({ origin: siteOrigin, locale, path: "/credits", title: t("meta.credits_title"), description: t("credits.lead") });
}

/** Crédits des photos Wikimedia Commons (obligation des licences CC BY et CC BY-SA). */
export default async function CreditsPage({ params }: PageProps<"/[locale]/credits">) {
  await pageLocale(params);
  const t = await getTranslations("web");
  return (
    <div className="wrap" style={{ paddingBlock: "var(--space-16) var(--section)" }}>
      <h1 className="h2">{t("credits.title")}</h1>
      <p className="lead mt16">{t("credits.lead")}</p>
      <ul className="grid g3 mt32" style={{ listStyle: "none", padding: 0 }}>
        {Object.entries(PHOTOS).map(([name, photo]) => (
          <li key={name} className="card flush">
            <div className="photo" style={{ blockSize: 180, borderRadius: 0 }}>
              <Image src={photo.image} alt="" fill sizes="(max-width: 900px) 100vw, 380px" placeholder="blur" />
            </div>
            <div style={{ padding: "var(--space-4)" }}>
              <h2 style={{ fontSize: "var(--text-md)" }} lang="en">
                {photo.title}
              </h2>
              <p className="small muted mt8">{t("credits.author", { author: photo.author })}</p>
              <p className="small muted">{t("credits.license", { license: photo.license })}</p>
              <a className="small" href={photo.source} rel="noopener noreferrer" target="_blank" style={{ display: "inline-flex", minBlockSize: "var(--size-touch-target)", alignItems: "center" }}>
                {t("credits.source")}
                <span className="sr-only"> {t("a11y.external")}</span>
              </a>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
