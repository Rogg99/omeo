import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";

import { FaqItems } from "@/components/FaqList";
import { JsonLd } from "@/components/JsonLd";
import { ComparisonTable, PlanCards } from "@/components/PlanCards";
import { metadataLocale, pageLocale } from "@/i18n/page";
import { rich } from "@/i18n/rich";
import { localizedUrl, pageMetadata } from "@/lib/seo";
import source from "@/server/data/source";
import type { PlanCatalog } from "@/server/data/types";
import { siteOrigin } from "@/server/env";

export async function generateMetadata({ params }: PageProps<"/[locale]/pricing">): Promise<Metadata> {
  const locale = await metadataLocale(params);
  if (!locale) return {};
  const t = await getTranslations({ locale, namespace: "web.meta" });
  return pageMetadata({ origin: siteOrigin, locale, path: "/pricing", title: t("pricing_title"), description: t("pricing_description") });
}

/** Catégorie de la FAQ consacrée à l'abonnement : celle qui contient la question sur la résiliation. */
const SUBSCRIPTION_FAQ = "0f6b1a52-0c1e-4d3a-9a51-000000000006";

function productJsonLd(catalog: PlanCatalog, url: string, description: string) {
  return {
    "@context": "https://schema.org",
    "@type": "Product",
    name: "Omeo Plus",
    description,
    brand: { "@type": "Brand", name: "Omeo" },
    offers: catalog.plans
      .filter((p) => p.interval !== "none")
      .map((p) => ({
        "@type": "Offer",
        name: p.name,
        price: (p.price.amount_cents / 100).toFixed(2),
        priceCurrency: p.price.currency,
        url,
        availability: "https://schema.org/InStock",
      })),
  };
}

export default async function PricingPage({ params }: PageProps<"/[locale]/pricing">) {
  const locale = await pageLocale(params);
  const [t, tm, catalog, faq] = await Promise.all([
    getTranslations("web.pricing"),
    getTranslations("web.meta"),
    source.content.plans(locale),
    source.content.faq(locale),
  ]);
  const subscriptionFaq = faq.ok ? faq.data.find((c) => c.items.some((i) => i.id === SUBSCRIPTION_FAQ)) : undefined;

  return (
    <>
      <header className="page-head wrap center">
        <p className="eyebrow">{t("eyebrow")}</p>
        <h1 className="h1 mt16">{t.rich("title", rich)}</h1>
        <p className="lead mt24 narrow">{t("lead")}</p>
        <p className="mt24">
          <span className="tag orange">{t("trial_tag")}</span>
        </p>
      </header>
      <section className="wrap" aria-labelledby="plans-title">
        <h2 id="plans-title" className="sr-only">
          {tm("pricing_title")}
        </h2>
        {catalog.ok ? <PlanCards plans={catalog.data.plans} comparison={catalog.data.comparison} /> : <p className="note warn">{t("unavailable")}</p>}
        <p className="small muted center mt24">{t("payment_note")}</p>
      </section>
      {catalog.ok ? (
        <section className="section wrap" aria-labelledby="compare-title">
          <h2 id="compare-title" className="h2 center">
            {t("compare_title")}
          </h2>
          <div className="mt32">
            <ComparisonTable rows={catalog.data.comparison} />
          </div>
        </section>
      ) : null}
      {subscriptionFaq ? (
        <section className="section narrow" style={{ paddingBlockStart: 0 }} aria-labelledby="pricing-faq">
          <h2 id="pricing-faq" className="h2 center">
            {t("faq_title")}
          </h2>
          <div className="mt32">
            <FaqItems items={subscriptionFaq.items} locale={locale} />
          </div>
        </section>
      ) : null}
      {catalog.ok ? <JsonLd data={productJsonLd(catalog.data, localizedUrl(siteOrigin, locale, "/pricing"), tm("pricing_description"))} /> : null}
    </>
  );
}
