import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";

import { FaqItems } from "@/components/FaqList";
import { Icon } from "@/components/icons/Icon";
import type { IconName } from "@/components/icons/paths";
import { JsonLd } from "@/components/JsonLd";
import { Logo } from "@/components/Logo";
import { Photo } from "@/components/Photo";
import { PlanCards } from "@/components/PlanCards";
import { QrCode } from "@/components/QrCode";
import { StoreButtons } from "@/components/StoreButtons";
import { Link } from "@/i18n/navigation";
import { metadataLocale, pageLocale } from "@/i18n/page";
import { rich, richOnBrand } from "@/i18n/rich";
import { pageMetadata } from "@/lib/seo";
import source from "@/server/data/source";
import { siteOrigin } from "@/server/env";
import { appStoreUrl, playStoreUrl } from "@/server/stores";

export async function generateMetadata({ params }: PageProps<"/[locale]">): Promise<Metadata> {
  const locale = await metadataLocale(params);
  if (!locale) return {};
  const t = await getTranslations({ locale, namespace: "web.meta" });
  return pageMetadata({ origin: siteOrigin, locale, path: "/", title: t("default_title"), description: t("default_description"), absoluteTitle: true });
}

/** Semaine type de l'illustration « Balance » : [mangé, dépensé] en kcal (maquette, pas une donnée). */
const BALANCE_WEEK: [number, number][] = [
  [2100, 2500],
  [2480, 2300],
  [1950, 2600],
  [2290, 2450],
  [2640, 2900],
  [2210, 2700],
  [1450, 2610],
];
const BALANCE_MAX = 3000;

const CITIES = ["Dakar", "Abidjan", "Yaoundé", "Douala", "Lomé", "Cotonou", "Paris"];

export default async function HomePage({ params }: PageProps<"/[locale]">) {
  const locale = await pageLocale(params);
  const [t, plans, faq] = await Promise.all([getTranslations("web"), source.content.plans(locale), source.content.faq(locale)]);
  const faqItems = faq.ok ? faq.data.flatMap((c) => c.items).slice(0, 4) : [];
  const days = t("home.balance_days").split(",");

  const tiles: { tone: "dark" | "light" | "black"; key: string; screen: React.ReactNode }[] = [
    {
      tone: "dark",
      key: "tile1",
      screen: (
        <>
          <Photo name="thieb" alt="" height={150} sizes="230px" />
          <div className="pill-cta">{t("home.tile1_cta")}</div>
        </>
      ),
    },
    {
      tone: "light",
      key: "tile2",
      screen: (
        <>
          {(["tile2_item1", "tile2_item2", "tile2_item3", "tile2_item4"] as const).map((k, i) => (
            <div key={k} className="line-item">
              <span>✓ {t(`home.${k}`)}</span>
              <b>{[180, 150, 60, 50][i]} g</b>
            </div>
          ))}
        </>
      ),
    },
    {
      tone: "black",
      key: "tile3",
      screen: (
        <>
          {[640, 810, null, null].map((kcal, i) => (
            <div key={i} className="mock-card" style={{ marginBlockStart: "var(--space-2)", display: "flex", justifyContent: "space-between" }}>
              <span>{t(`home.tile3_meal${i + 1}` as "home.tile3_meal1")}</span>
              <b>{kcal ?? "—"}</b>
            </div>
          ))}
        </>
      ),
    },
    {
      tone: "light",
      key: "tile4",
      screen: (
        <svg viewBox="0 0 200 110" style={{ inlineSize: "100%" }} aria-hidden="true">
          <path d="M0 80 C30 70 50 90 80 60 S140 30 200 40" fill="none" stroke="var(--sage-700)" strokeWidth="3" />
          <line x1="0" x2="200" y1="50" y2="50" stroke="var(--orange-500)" strokeDasharray="4 4" />
        </svg>
      ),
    },
    {
      tone: "dark",
      key: "tile5",
      screen: (
        <>
          <Photo name="sport" alt="" height={130} sizes="230px" />
          <p style={{ marginBlockStart: "var(--space-3)", fontWeight: "var(--weight-semibold)" }}>{t("home.tile5_session")}</p>
        </>
      ),
    },
    {
      tone: "black",
      key: "tile6",
      screen: (
        <div className="mock-card">
          <b>{t("home.tile6_challenge")}</b>
          <div style={{ display: "flex", gap: 3, marginBlockStart: "var(--space-2)" }}>
            {Array.from({ length: 14 }, (_, i) => (
              <i key={i} style={{ flex: 1, blockSize: 18, borderRadius: 4, background: i < 9 ? "var(--sage-700)" : "var(--cream-200)" }} />
            ))}
          </div>
        </div>
      ),
    },
  ];

  const sportItems: [IconName, string][] = [
    ["footprints", t("home.sport_item1")],
    ["pulse", t("home.sport_item2")],
    ["dumbbell", t("home.sport_item3")],
  ];

  return (
    <>
      <section className="hero" aria-labelledby="hero-title">
        <div className="wrap">
          <div className="copy">
            <span className="tag glass">
              <Icon name="sparkles" />
              {t("home.hero_tag")}
            </span>
            <h1 id="hero-title" className="h1 mt24">
              {t.rich("hero.title_rich", richOnBrand)}
            </h1>
            <p className="lead mt24" style={{ maxInlineSize: 520 }}>
              {t("home.hero_lead")}
            </p>
            <div className="row wrapf mt32" id="download" style={{ scrollMarginBlockStart: 96 }}>
              <StoreButtons />
              <div className="row hide-m" style={{ marginInlineStart: "var(--space-3)" }}>
                <QrCode />
                <span className="small hero-note" style={{ maxInlineSize: 110 }}>
                  {t("store.qr_hint")}
                </span>
              </div>
            </div>
            <p className="small mt24 hero-note">{t("home.hero_note")}</p>
          </div>
          <div className="hero-visual">
            <div className="phone" role="img" aria-label={t("home.phone_alt")}>
              <div className="scr" aria-hidden="true">
                <Logo size={22} />
                <p style={{ marginBlockStart: "var(--space-3)", fontSize: 10, opacity: 0.7, letterSpacing: "0.1em", textTransform: "uppercase" }}>
                  {t("home.phone_date")}
                </p>
                <b style={{ font: "var(--weight-semibold) 18px var(--font-display)" }}>{t("home.phone_greeting")}</b>
                <div className="mock-card">
                  <b>{t("home.phone_nutrition")}</b>
                  <div className="row" style={{ marginBlockStart: "var(--space-2)", gap: "var(--space-3)" }}>
                    <svg width="86" height="86" viewBox="0 0 86 86">
                      <circle cx="43" cy="43" r="36" fill="none" stroke="var(--cream-200)" strokeWidth="9" />
                      <circle cx="43" cy="43" r="36" fill="none" stroke="var(--sage-700)" strokeWidth="9" strokeDasharray="226" strokeDashoffset="80" strokeLinecap="round" transform="rotate(-90 43 43)" />
                      <text x="43" y="48" textAnchor="middle" style={{ font: "var(--weight-semibold) 15px var(--font-display)" }}>
                        890
                      </text>
                    </svg>
                    <div className="grow" style={{ display: "grid", gap: "var(--space-2)" }}>
                      {(
                        [
                          ["phone_protein", 66, "var(--data-protein)"],
                          ["phone_carbs", 67, "var(--data-carbs)"],
                          ["phone_fat", 58, "var(--data-fat)"],
                        ] as const
                      ).map(([k, pct, color]) => (
                        <div key={k}>
                          <div style={{ fontSize: 10, fontWeight: 600 }}>{t(`home.${k}`)}</div>
                          <div className="bar">
                            <i style={{ inlineSize: `${pct}%`, background: color }} />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
                <div style={{ marginBlockStart: "var(--space-3)" }}>
                  <Photo name="thieb" alt="" height={150} sizes="280px" priority />
                </div>
                <div className="mock-card ink">
                  <b>{t("home.phone_photo")}</b>
                  <div style={{ fontSize: 10, opacity: 0.75 }}>{t("home.phone_analyses")}</div>
                </div>
              </div>
            </div>
            <div className="float a hide-m" aria-hidden="true">
              <span className="ib sm orange">
                <Icon name="camera" />
              </span>
              <div>
                <b>{t("home.float_dish")}</b>
                <div className="xs faint">{t("home.float_dish_hint")}</div>
              </div>
            </div>
            <div className="float b hide-m" aria-hidden="true">
              <span className="ib sm">
                <Icon name="flame" />
              </span>
              <div>
                <b>{t("home.float_kcal")}</b>
                <div className="xs faint">{t("home.float_kcal_hint")}</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="section tight" style={{ paddingBlockStart: 150 }}>
        <div className="wrap">
          <p className="center small faint">{t("home.proof")}</p>
          <ul className="proof mt16" style={{ listStyle: "none", padding: 0 }}>
            {CITIES.map((city) => (
              <li key={city}>{city}</li>
            ))}
          </ul>
        </div>
      </section>

      <section className="section" style={{ paddingBlockStart: "var(--space-10)" }} aria-labelledby="how-title">
        <div className="wrap">
          <p className="eyebrow">{t("home.how_eyebrow")}</p>
          <h2 id="how-title" className="h2 mt16" style={{ maxInlineSize: 720 }}>
            {t.rich("home.how_title", rich)}
          </h2>
          <div className="board mt48">
            {tiles.map((tile, i) => (
              <article key={tile.key} className={`tile ${tile.tone}`}>
                <span className="num">{t("home.tile_count", { n: String(i + 1).padStart(2, "0") })}</span>
                <h3>{t.rich(`home.${tile.key}_title` as "home.tile1_title", tile.tone === "light" ? rich : richOnBrand)}</h3>
                <p>{t(`home.${tile.key}_body` as "home.tile1_body")}</p>
                <div className="mini" aria-hidden="true">
                  <div>
                    <div>{tile.screen}</div>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="section soft" aria-labelledby="sport-title">
        <div className="wrap grid g2" style={{ alignItems: "center", gap: "var(--space-16)" }}>
          <div>
            <p className="eyebrow">{t("home.sport_eyebrow")}</p>
            <h2 id="sport-title" className="h2 mt16">
              {t.rich("home.sport_title", rich)}
            </h2>
            <p className="lead mt24">{t("home.sport_lead")}</p>
            <ul className="stack mt32" style={{ listStyle: "none", padding: 0 }}>
              {sportItems.map(([icon, label]) => (
                <li key={icon} className="row">
                  <span className="ib">
                    <Icon name={icon} />
                  </span>
                  <b>{label}</b>
                </li>
              ))}
            </ul>
          </div>
          <div className="card ink" style={{ padding: "var(--space-8)" }}>
            <div className="row wrapf" style={{ justifyContent: "space-between" }}>
              <h3 style={{ fontSize: "var(--text-lg)" }}>{t("home.balance_title")}</h3>
              <span className="tag">{t("home.balance_goal")}</span>
            </div>
            <dl className="grid g3 mt32 center" style={{ gridTemplateColumns: "repeat(3, minmax(0, 1fr))" }}>
              {(
                [
                  ["balance_eaten", "balance_eaten_value"],
                  ["balance_burned", "balance_burned_value"],
                  ["balance_gap", "balance_gap_value"],
                ] as const
              ).map(([label, value]) => (
                <div key={label}>
                  <dt className="stat-label">{t(`home.${label}`)}</dt>
                  <dd className="stat" style={{ margin: 0 }}>
                    {t(`home.${value}`)}
                  </dd>
                </div>
              ))}
            </dl>
            <div className="bars mt32" role="img" aria-label={t("home.balance_chart")}>
              {BALANCE_WEEK.map(([eaten, burned], i) => (
                <div key={i} aria-hidden="true">
                  <div className="pair">
                    <i className="eaten" style={{ blockSize: `${(eaten / BALANCE_MAX) * 100}%` }} />
                    <i className="burned" style={{ blockSize: `${(burned / BALANCE_MAX) * 100}%` }} />
                  </div>
                  <span className="xs">{days[i]}</span>
                </div>
              ))}
            </div>
            <p className="xs mt24" style={{ opacity: 0.8 }}>
              {t("home.balance_note")}
            </p>
          </div>
        </div>
      </section>

      <section className="section" aria-labelledby="content-title">
        <div className="wrap">
          <div className="row wrapf" style={{ alignItems: "flex-end" }}>
            <div className="grow">
              <p className="eyebrow">{t("home.content_eyebrow")}</p>
              <h2 id="content-title" className="h2 mt16">
                {t.rich("home.content_title", rich)}
              </h2>
            </div>
            <p className="muted" style={{ maxInlineSize: 400 }}>
              {t("home.content_lead")}
            </p>
          </div>
          <ul className="grid g4 mt48" style={{ listStyle: "none", padding: 0 }}>
            {(["ndole", "yassa", "baobab", "moringa"] as const).map((name) => (
              <li key={name} className="card flush">
                <Photo name={name} alt="" height={200} sizes="(max-width: 900px) 100vw, 280px" radius="0" />
                <div style={{ padding: "var(--space-4)" }}>
                  <h3 style={{ fontSize: "var(--text-lg)" }}>{t(`home.content_${name}`)}</h3>
                  <p className="small muted">{t(`home.content_${name}_meta`)}</p>
                </div>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="section brand" aria-labelledby="pricing-title">
        <div className="wrap center">
          <p className="eyebrow">{t("home.pricing_eyebrow")}</p>
          <h2 id="pricing-title" className="h2 mt16">
            {t.rich("home.pricing_title", richOnBrand)}
          </h2>
          <div className="mt48" style={{ textAlign: "start", color: "var(--text)" }}>
            {plans.ok ? <PlanCards plans={plans.data.plans} comparison={plans.data.comparison} /> : <p className="note warn">{t("pricing.unavailable")}</p>}
          </div>
          <Link className="btn light mt48" href="/pricing">
            {t("home.pricing_cta")}
          </Link>
        </div>
      </section>

      <section className="section" aria-labelledby="quotes-title">
        <div className="wrap">
          <p className="eyebrow">{t("home.quotes_eyebrow")}</p>
          <h2 id="quotes-title" className="h2 mt16">
            {t.rich("home.quotes_title", rich)}
          </h2>
          <ul className="grid g3 mt48" style={{ listStyle: "none", padding: 0 }}>
            {([1, 2, 3] as const).map((n) => (
              <li key={n} className="card">
                <figure style={{ margin: 0 }}>
                  <p aria-label={t("a11y.rating", { stars: 5 })} style={{ color: "var(--accent)" }}>
                    <span aria-hidden="true">★★★★★</span>
                  </p>
                  <blockquote className="mt16" style={{ margin: 0, fontSize: "var(--text-lg)" }}>
                    {t(`home.quote${n}`)}
                  </blockquote>
                  <figcaption className="mt24 small">
                    <b>{t(`home.quote${n}_name`)}</b> · <span className="muted">{t(`home.quote${n}_city`)}</span>
                  </figcaption>
                </figure>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {faqItems.length > 0 ? (
        <section className="section" style={{ paddingBlockStart: 0 }} aria-labelledby="faq-title">
          <div className="narrow">
            <h2 id="faq-title" className="h2 center">
              {t("home.faq_title")}
            </h2>
            <div className="mt32">
              <FaqItems items={faqItems} />
            </div>
            <p className="center mt32">
              <Link className="btn ghost" href="/faq">
                {t("home.faq_cta")}
              </Link>
            </p>
          </div>
        </section>
      ) : null}

      <section className="section tight" aria-labelledby="final-title">
        <div className="wrap">
          <div className="card ink row wrapf" style={{ padding: "clamp(var(--space-8), 6vw, var(--space-16))", justifyContent: "space-between", gap: "var(--space-10)", borderRadius: "calc(var(--r-xl) * 1.25)" }}>
            <div>
              <h2 id="final-title" className="h2">
                {t.rich("home.final_title", richOnBrand)}
              </h2>
              <div className="mt32">
                <StoreButtons raised />
              </div>
            </div>
            <div className="hide-m">
              <QrCode />
            </div>
          </div>
        </div>
      </section>

      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "SoftwareApplication",
          name: "Omeo",
          applicationCategory: "HealthApplication",
          operatingSystem: "Android, iOS",
          description: t("meta.app_description"),
          downloadUrl: [playStoreUrl(), appStoreUrl()],
          offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
        }}
      />
    </>
  );
}
