import { getTranslations } from "next-intl/server";

import { Link } from "@/i18n/navigation";
import type { CatalogPlan, ComparisonRow } from "@/server/data/types";

import { Icon } from "./icons/Icon";

/** Lignes du comparatif incluses dans une offre (valeurs et libellés renvoyés par l'API). */
function included(rows: ComparisonRow[], column: "free" | "plus"): { label: string; value: string }[] {
  return rows.filter((r) => r[column] !== "—" && r[column] !== "").map((r) => ({ label: r.label, value: r[column] }));
}

/** Cartes des offres : prix, équivalent mensuel et économie viennent de /billing/plans. */
export async function PlanCards({ plans, comparison }: { plans: CatalogPlan[]; comparison: ComparisonRow[] }) {
  const t = await getTranslations("web.pricing");
  return (
    <div className="plans">
      {plans.map((plan) => {
        const isFree = plan.interval === "none";
        const rows = included(comparison, isFree ? "free" : "plus").slice(0, 6);
        return (
          <article key={plan.code} className={`plan${plan.featured ? " feat" : ""}`} aria-labelledby={`plan-${plan.code}`}>
            <div className="row" style={{ justifyContent: "space-between" }}>
              <h3 id={`plan-${plan.code}`} className="h3">
                {plan.name}
              </h3>
              {plan.featured ? (
                <span className="tag orange">
                  {plan.savings_percent ? t("best_offer_savings", { percent: plan.savings_percent }) : t("best_offer")}
                </span>
              ) : null}
            </div>
            <p className="price">
              {plan.price.formatted}
              {plan.interval === "month" ? <small> {t("per_month")}</small> : null}
              {plan.interval === "year" ? <small> {t("per_year")}</small> : null}
            </p>
            <p className="muted small mt8">
              {plan.monthly_equivalent
                ? t("monthly_equivalent", { amount: plan.monthly_equivalent.formatted ?? "" })
                : isFree
                  ? t("free_lead")
                  : t("monthly_lead")}
            </p>
            <ul>
              {rows.map((row) => (
                <li key={row.label}>
                  <Icon name="check" />
                  <span>
                    {row.label}
                    {row.value !== "✓" ? ` · ${row.value}` : ""}
                  </span>
                </li>
              ))}
              {!isFree ? (
                <li>
                  <Icon name="check" />
                  <span>{t("cancel_anytime")}</span>
                </li>
              ) : null}
            </ul>
            {isFree ? (
              <Link className="btn ghost" href="/#download">
                {t("download_cta")}
              </Link>
            ) : (
              <Link className={`btn ${plan.featured ? "light" : "green"}`} href={{ pathname: "/subscription", query: { plan: plan.code } }}>
                {t("subscribe_cta")}
              </Link>
            )}
          </article>
        );
      })}
    </div>
  );
}

/** Comparatif détaillé (tableau accessible, défilement horizontal sur petit écran). */
export async function ComparisonTable({ rows }: { rows: ComparisonRow[] }) {
  const t = await getTranslations("web.pricing");
  const hasTrial = rows.some((r) => r.trial !== undefined);
  return (
    // Zone défilante atteignable au clavier (petits écrans)
    <div className="table-scroll card" style={{ padding: "var(--space-2)" }} tabIndex={0} role="region" aria-label={t("compare_caption")}>
      <table className="cmp">
        <caption className="sr-only">{t("compare_caption")}</caption>
        <thead>
          <tr>
            <th scope="col">{t("compare_feature")}</th>
            {hasTrial ? <th scope="col">{t("plan_trial")}</th> : null}
            <th scope="col">{t("plan_free")}</th>
            <th scope="col">{t("plan_plus")}</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.feature}>
              <th scope="row" style={{ fontWeight: "var(--weight-regular)" }}>
                {row.label}
              </th>
              {hasTrial ? <td>{row.trial ?? "—"}</td> : null}
              <td>{row.free}</td>
              <td>{row.plus}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
