import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";

import { faqJsonLd, FaqItems } from "@/components/FaqList";
import { FaqSearch } from "@/components/FaqSearch";
import { slugify } from "@/components/Markdown";
import { JsonLd } from "@/components/JsonLd";
import { Link } from "@/i18n/navigation";
import { metadataLocale, pageLocale } from "@/i18n/page";
import { rich } from "@/i18n/rich";
import { pageMetadata } from "@/lib/seo";
import source from "@/server/data/source";
import { siteOrigin } from "@/server/env";

export async function generateMetadata({ params }: PageProps<"/[locale]/faq">): Promise<Metadata> {
  const locale = await metadataLocale(params);
  if (!locale) return {};
  const t = await getTranslations({ locale, namespace: "web.meta" });
  return pageMetadata({ origin: siteOrigin, locale, path: "/faq", title: t("faq_title"), description: t("faq_description") });
}

export default async function FaqPage({ params }: PageProps<"/[locale]/faq">) {
  const locale = await pageLocale(params);
  const [t, faq] = await Promise.all([getTranslations("web.faq"), source.content.faq(locale)]);
  const categories = faq.ok ? faq.data.filter((c) => c.items.length > 0) : [];
  const total = categories.reduce((n, c) => n + c.items.length, 0);
  const results = Array.from({ length: total + 1 }, (_, count) => t("results", { count }));

  return (
    <>
      <header className="page-head narrow center">
        <p className="eyebrow">{t("eyebrow")}</p>
        <h1 className="h1 mt16">{t.rich("title", rich)}</h1>
        {categories.length > 0 ? (
          <div className="mt32" style={{ textAlign: "start" }}>
            <FaqSearch label={t("search_label")} placeholder={t("search_placeholder")} results={results} target="faq-list" />
          </div>
        ) : null}
      </header>
      <div className="narrow" style={{ paddingBlockEnd: "var(--section)" }}>
        {categories.length === 0 ? (
          <p className="note info">{t("empty")}</p>
        ) : (
          <>
            <nav aria-label={t("topics")} className="chips">
              {categories.map((c) => (
                <a key={c.category} className="chip" href={`#${slugify(c.category)}`}>
                  {c.category}
                </a>
              ))}
            </nav>
            <div id="faq-list" className="mt32">
              {categories.map((c) => (
                <section key={c.category} data-faq-group aria-labelledby={slugify(c.category)} className="mt32">
                  <h2 id={slugify(c.category)} className="h3" style={{ scrollMarginBlockStart: 96 }}>
                    {c.category}
                  </h2>
                  <FaqItems items={c.items} />
                </section>
              ))}
            </div>
            <JsonLd data={faqJsonLd(categories)} />
          </>
        )}
        <div className="card soft center mt48">
          <h2 className="h3">{t("more_title")}</h2>
          <p className="muted mt8">{t("more_lead")}</p>
          <Link className="btn mt24" href="/contact">
            {t("more_cta")}
          </Link>
        </div>
      </div>
    </>
  );
}
