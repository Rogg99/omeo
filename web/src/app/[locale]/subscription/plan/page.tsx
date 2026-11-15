import { randomUUID } from "node:crypto";

import { connection } from "next/server";
import { getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { Link } from "@/i18n/navigation";
import { pageLocale } from "@/i18n/page";
import { rich } from "@/i18n/rich";
import source from "@/server/data/source";
import { errorMessage } from "@/server/forms";
import { sessionEmail } from "@/server/session";
import { ensureStep, loadSubscription } from "@/server/subscription";

import { logout } from "../actions";
import { Steps } from "../Steps";
import { PlanForm, type PlanOption } from "./PlanForm";

const PAID: readonly string[] = ["plus_annual", "plus_monthly"];

/** Étape 2 : choix de l'offre (annuelle mise en avant), code promo vérifié par l'API. */
export default async function PlanPage({ params, searchParams }: PageProps<"/[locale]/subscription/plan">) {
  const locale = await pageLocale(params);
  const page = await loadSubscription(locale);
  const [t, catalog, query] = await Promise.all([getTranslations("web.subscription"), source.content.plans(locale), searchParams]);
  await connection();

  if (!("state" in page)) {
    return (
      <p className="note danger" role="alert">
        <Icon name="alert" />
        <span>{await errorMessage(page.problem.code)}</span>
      </p>
    );
  }
  const { state } = page;
  ensureStep(locale, state, "plan");

  const plans = catalog.ok ? catalog.data.plans.filter((p) => PAID.includes(p.code)) : [];
  const options: PlanOption[] = plans.map((p) => ({
    code: p.code as PlanOption["code"],
    title: p.interval === "year" ? t("annual") : t("monthly"),
    price: p.price.formatted ?? "",
    detail:
      p.interval === "year" && p.monthly_equivalent
        ? t("annual_detail", { monthly: p.monthly_equivalent.formatted ?? "", price: p.price.formatted ?? "" })
        : t("monthly_detail"),
    savings: p.savings_percent ? t("savings", { percent: p.savings_percent }) : undefined,
  }));
  const featured = plans.find((p) => p.featured)?.code ?? options[0]?.code;
  const requested = options.find((o) => o.code === query.plan)?.code;

  const email = await sessionEmail();
  const tier = state.entitlements.tier;
  const current =
    tier === "trial"
      ? t.rich("current_trial", { ...rich, days: state.trial_days_left ?? 0 })
      : tier === "plus"
        ? t.rich("current_plus", rich)
        : t.rich("current_free", rich);

  return (
    <>
      <Steps current={1} />
      <h1 className="h2 mt32">{t("plan_title")}</h1>
      <div className="row wrapf mt16 small muted" style={{ gap: "var(--space-2)" }}>
        <span>
          {email ? t.rich("signed_in_as", { ...rich, email }) : null} {current}
        </span>
        <form action={logout}>
          <button type="submit" className="link-btn">
            {t("switch_account")}
          </button>
        </form>
      </div>

      {state.granted_days_left ? (
        <div className="note info mt24">
          <Icon name="gift" />
          <div>
            <b>{t("granted_title")}</b>
            <p>{t("granted_lead")}</p>
          </div>
        </div>
      ) : null}

      {!state.web_checkout_allowed ? (
        <p className="note warn mt24" role="status">
          <Icon name="info" />
          <span>{t("store_conflict")}</span>
        </p>
      ) : options.length === 0 || !featured ? (
        <p className="note warn mt24">{(await getTranslations("web.pricing"))("unavailable")}</p>
      ) : (
        <PlanForm
          options={options}
          initial={requested ?? (featured as PlanOption["code"])}
          idempotencyKey={randomUUID()}
          labels={{
            question: t("promo_question"),
            add: t("promo_add"),
            label: t("promo_label"),
            check: t("promo_check"),
            checking: t("promo_checking"),
            valid: t.raw("promo_valid") as string,
            invalid: t("promo_invalid"),
            remove: t("promo_remove"),
            submit: t("continue_payment"),
            redirecting: t("redirecting"),
            networkError: await errorMessage("network_error"),
          }}
          footer={
            <>
              <p className="small muted">{t("payment_note")}</p>
              <p className="xs faint">{t.rich("terms_note", { link: (c) => <Link href="/legal/terms">{c}</Link> })}</p>
            </>
          }
        />
      )}
    </>
  );
}

