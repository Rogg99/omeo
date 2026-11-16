import type { Metadata } from "next";
import Link from "next/link";
import { getTranslations } from "next-intl/server";

import { SeriesChart } from "@/components/charts/SeriesChart";
import { SegmentFilter, SelectFilter } from "@/components/ui/Filters";
import { Bar, Kpi } from "@/components/ui/Kpi";
import { PageHeader } from "@/components/ui/PageHeader";
import { formatNumber, formatRatio } from "@/lib/format";
import { LOCALES, isLocale } from "@/lib/locales";
import { load, requirePermission } from "@/server/auth";
import source from "@/server/data/source";

export async function generateMetadata(): Promise<Metadata> {
  return { title: (await getTranslations("admin.nav"))("dashboard") };
}

const PERIODS = { "7d": 7, "30d": 30, "90d": 90, "12m": 365 } as const;
type Period = keyof typeof PERIODS;
const COUNTRIES = ["CM", "SN", "CI", "ML", "GH", "TG", "FR"] as const;
const PLATFORMS = ["android", "ios", "web"] as const;

const isoDay = (d: Date) => d.toISOString().slice(0, 10);
const one = (v: string | string[] | undefined) => (typeof v === "string" ? v : undefined);

/**
 * Tableau de bord. Filtres dans l'URL (période, pays, langue, plateforme). Les blocs que la
 * personne n'a pas le droit de voir arrivent à `null` de l'API et ne sont pas affichés.
 */
export default async function DashboardPage({ searchParams }: PageProps<"/">) {
  const { ctx, can } = await requirePermission("dashboard.product");
  const params = await searchParams;
  const t = await getTranslations("admin.dashboard");
  const tc = await getTranslations("admin.common");

  const period: Period = (one(params.period) as Period) in PERIODS ? (one(params.period) as Period) : "30d";
  const to = new Date();
  const from = new Date(to.getTime() - PERIODS[period] * 86_400_000);
  const country = one(params.country);
  const locale = one(params.locale);
  const platform = one(params.platform);

  const d = await load(
    source.dashboard.get(
      {
        from: isoDay(from),
        to: isoDay(to),
        ...(country && (COUNTRIES as readonly string[]).includes(country) ? { country } : {}),
        ...(isLocale(locale) ? { locale } : {}),
        ...(platform && (PLATFORMS as readonly string[]).includes(platform)
          ? { platform: platform as (typeof PLATFORMS)[number] }
          : {}),
      },
      ctx,
    ),
  );

  const delta = (value: number | null | undefined) =>
    value === null || value === undefined ? undefined : t("delta", { value: Math.abs(value), sign: value >= 0 ? "plus" : "minus" });

  return (
    <div className="page">
      <PageHeader
        title={t("title")}
        subtitle={t("subtitle")}
        actions={
          <SegmentFilter
            label={t("period")}
            param="period"
            fallback="30d"
            options={(Object.keys(PERIODS) as Period[]).map((p) => ({ value: p, label: t(`period_${p}`) }))}
          />
        }
      />
      <div className="row" style={{ flexWrap: "wrap", marginBottom: 16 }}>
        <SelectFilter label={t("country")} param="country" allLabel={tc("all")} options={COUNTRIES.map((c) => ({ value: c, label: c }))} />
        <SelectFilter
          label={t("locale")}
          param="locale"
          allLabel={tc("all")}
          options={LOCALES.map((l) => ({ value: l, label: l.toUpperCase() }))}
        />
        <SelectFilter
          label={t("platform")}
          param="platform"
          allLabel={tc("all")}
          options={PLATFORMS.map((p) => ({ value: p, label: t(`platform_${p}`) }))}
        />
      </div>

      <div className="grid g4">
        {d.signups ? (
          <Kpi
            icon="users"
            label={t("signups")}
            value={formatNumber(d.signups.total)}
            delta={delta(d.signups.delta_percent)}
            trend={(d.signups.delta_percent ?? 0) >= 0 ? "up" : "down"}
          />
        ) : null}
        {d.active_users ? <Kpi icon="pulse" label={t("mau")} value={formatNumber(d.active_users.mau)} delta={t("dau_wau", { dau: d.active_users.dau ?? 0, wau: d.active_users.wau ?? 0 })} /> : null}
        {d.trial_to_plus_rate !== null && d.trial_to_plus_rate !== undefined ? (
          <Kpi icon="crown" label={t("trial_to_plus")} value={formatRatio(d.trial_to_plus_rate)} />
        ) : null}
        {d.mrr ? <Kpi icon="dollar" label={t("mrr")} value={d.mrr.formatted ?? "—"} /> : null}
      </div>

      <div className="grid g-21" style={{ marginTop: 16 }}>
        {d.signups?.series ? (
          <section className="card" aria-labelledby="chart-signups">
            <div className="ch">
              <h3 id="chart-signups">{t("signups_chart")}</h3>
            </div>
            <SeriesChart points={d.signups.series} label={t("signups")} />
          </section>
        ) : null}
        {d.retention ? (
          <section className="card" aria-labelledby="retention">
            <div className="ch">
              <h3 id="retention">{t("retention")}</h3>
            </div>
            {(["d1", "d7", "d30"] as const).map((k) => (
              <div key={k} className="list-i">
                <span style={{ width: 40 }} className="bold">
                  {t(`retention_${k}`)}
                </span>
                <span style={{ flex: 1 }}>
                  <Bar ratio={d.retention?.[k] ?? 0} label={formatRatio(d.retention?.[k])} />
                </span>
                <b className="small num" style={{ width: 56, textAlign: "end" }}>
                  {formatRatio(d.retention?.[k], 0)}
                </b>
              </div>
            ))}
          </section>
        ) : null}
      </div>

      <div className="grid g3" style={{ marginTop: 16 }}>
        {d.analyses ? (
          <section className="card" aria-labelledby="analyses">
            <div className="ch">
              <h3 id="analyses">{t("analyses")}</h3>
              {d.ai_cost ? <span className="r tag">{t("ai_cost", { amount: d.ai_cost.formatted ?? "" })}</span> : null}
            </div>
            <p className="kpi">
              <span className="v num">{formatNumber(d.analyses.total)}</span>
            </p>
            {d.analyses.series ? <SeriesChart points={d.analyses.series} label={t("analyses")} /> : null}
          </section>
        ) : null}
        {d.revenue_by_channel ? (
          <section className="card" aria-labelledby="revenue">
            <div className="ch">
              <h3 id="revenue">{t("revenue_by_channel")}</h3>
            </div>
            {d.revenue_by_channel.map((r) => {
              const max = Math.max(...(d.revenue_by_channel ?? []).map((x) => x.amount?.amount_cents ?? 0), 1);
              return (
                <div key={r.channel} className="list-i">
                  <span style={{ width: 110 }}>{t(`channel_${r.channel ?? "web"}`)}</span>
                  <span style={{ flex: 1 }}>
                    <Bar ratio={(r.amount?.amount_cents ?? 0) / max} label={r.amount?.formatted ?? ""} />
                  </span>
                  <b className="small num">{r.amount?.formatted}</b>
                </div>
              );
            })}
          </section>
        ) : null}
        <section className="card stack" aria-labelledby="quality">
          <div className="ch">
            <h3 id="quality">{t("quality")}</h3>
          </div>
          {d.negative_feedback_rate !== null && d.negative_feedback_rate !== undefined ? (
            <div className="row" style={{ justifyContent: "space-between" }}>
              <span>{t("negative_feedback")}</span>
              {can("feedback.view") ? (
                <Link href="/feedback?rating=down" className="bold num">
                  {formatRatio(d.negative_feedback_rate)}
                </Link>
              ) : (
                <b className="num">{formatRatio(d.negative_feedback_rate)}</b>
              )}
            </div>
          ) : null}
          {d.support_pending !== null && d.support_pending !== undefined ? (
            <div className="row" style={{ justifyContent: "space-between" }}>
              <span>{t("support_pending")}</span>
              <Link href="/support?status=open" className="bold num">
                {formatNumber(d.support_pending)}
              </Link>
            </div>
          ) : null}
        </section>
      </div>
    </div>
  );
}
