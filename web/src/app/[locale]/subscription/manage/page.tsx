import { getFormatter, getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { Link } from "@/i18n/navigation";
import { pageLocale } from "@/i18n/page";
import source from "@/server/data/source";
import type { Payment } from "@/server/data/types";
import { errorMessage } from "@/server/forms";
import { sessionEmail } from "@/server/session";
import { ensureStep, loadSubscription } from "@/server/subscription";

import { logout } from "../actions";
import { PaymentsList, PortalButton, type PaymentRow } from "./ManageIslands";

const PAYMENT_STATUSES = ["succeeded", "failed", "refunded", "pending"] as const;

/** Gestion d'un abonnement pris sur le site : état, portail de l'agrégateur, paiements. */
export default async function ManagePage({ params }: PageProps<"/[locale]/subscription/manage">) {
  const locale = await pageLocale(params);
  const page = await loadSubscription(locale);
  const [t, format, email, errors] = await Promise.all([
    getTranslations("web.subscription"),
    getFormatter(),
    sessionEmail(),
    getTranslations("errors"),
  ]);
  if (!("state" in page)) {
    return (
      <p className="note danger" role="alert">
        <Icon name="alert" />
        <span>{await errorMessage(page.problem.code)}</span>
      </p>
    );
  }
  ensureStep(locale, page.state, "manage");
  const subscription = page.state.subscription;
  const payments = await source.billing.payments(undefined, page.session);
  const date = (iso: string | null | undefined) => (iso ? format.dateTime(new Date(iso), { dateStyle: "long" }) : "—");
  const rows: PaymentRow[] = payments.ok
    ? ((payments.data.results ?? []) as Payment[]).map((p) => ({
        id: p.id,
        description: p.description ?? "",
        date: format.dateTime(new Date(p.paid_at), { dateStyle: "medium" }),
        amount: p.amount.formatted ?? "",
        status: p.status,
        receiptUrl: p.receipt_url ?? null,
      }))
    : [];

  return (
    <>
      <div className="row wrapf" style={{ justifyContent: "space-between" }}>
        <h1 className="h2">{t("manage_title")}</h1>
        <form action={logout}>
          <button type="submit" className="btn sm ghost">
            <Icon name="logout" />
            {t("logout")}
          </button>
        </form>
      </div>
      {email ? <p className="small muted mt8">{email}</p> : null}

      {subscription ? (
        <section className="card mt24" aria-labelledby="current-plan">
          <div className="row wrapf" style={{ justifyContent: "space-between" }}>
            <h2 id="current-plan" className="h3">
              {subscription.plan_name}
            </h2>
            <span className={`tag${subscription.status === "grace" ? " orange" : ""}`}>{t("status", { status: subscription.status })}</span>
          </div>
          <p className="muted mt8">
            {subscription.price?.formatted ? `${subscription.price.formatted} · ` : ""}
            {subscription.auto_renew
              ? t("renews_on", { date: date(subscription.current_period_end) })
              : t("active_until", { date: date(subscription.current_period_end) })}
          </p>
          {subscription.status === "grace" ? (
            <p className="note warn mt16" role="status">
              <Icon name="alert" />
              <span>{t("grace_warning")}</span>
            </p>
          ) : null}
        </section>
      ) : (
        <section className="card mt24">
          <h2 className="h3">{t("no_subscription_title")}</h2>
          <p className="muted mt8">{t("no_subscription_body")}</p>
          <Link className="btn green mt16" href="/subscription/plan">
            {t("subscribe")}
          </Link>
        </section>
      )}

      <section className="card mt24" aria-labelledby="portal-title">
        <h2 id="portal-title" className="h3">
          {t("portal_title")}
        </h2>
        <p className="muted mt8">{t("portal_body")}</p>
        <PortalButton label={t("portal_cta")} pending={t("redirecting")} />
      </section>

      <section className="card mt24" aria-labelledby="payments-title">
        <h2 id="payments-title" className="h3">
          {t("payments")}
        </h2>
        {rows.length === 0 ? (
          <p className="muted mt8">{t("payments_empty")}</p>
        ) : (
          <PaymentsList
            initial={rows}
            cursor={payments.ok ? payments.data.next_cursor : null}
            locale={locale}
            labels={{
              loadMore: t("load_more"),
              receipt: t("receipt"),
              external: (await getTranslations("web.a11y"))("external"),
              error: errors("network_error"),
              statuses: Object.fromEntries(PAYMENT_STATUSES.map((s) => [s, t("payment_status", { status: s })])),
            }}
          />
        )}
      </section>
    </>
  );
}
