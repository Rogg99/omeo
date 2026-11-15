import { getFormatter, getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { pageLocale } from "@/i18n/page";
import { ensureStep, loadSubscription, storeManagementUrl } from "@/server/subscription";

import { logout } from "../actions";

/** Abonnement pris dans un store : explication et lien vers le store, pas de double abonnement. */
export default async function StorePage({ params }: PageProps<"/[locale]/subscription/store">) {
  const locale = await pageLocale(params);
  const page = await loadSubscription(locale);
  const [t, format] = await Promise.all([getTranslations("web.subscription"), getFormatter()]);
  if (!("state" in page)) return null;
  ensureStep(locale, page.state, "store");
  const subscription = page.state.subscription;
  const channel = subscription?.channel ?? "other";

  return (
    <div className="card">
      <span className="ib">
        <Icon name="phone" />
      </span>
      <h1 className="h2 mt16">{t("store_title", { channel })}</h1>
      <p className="lead mt16">{t("store_lead", { channel })}</p>
      <p className="note info mt24">
        <Icon name="info" />
        <span>{t("store_no_double")}</span>
      </p>
      {subscription ? (
        <dl className="kv mt24">
          <dt>{t("offer")}</dt>
          <dd>{subscription.plan_name}</dd>
          <dt>{t("store_status")}</dt>
          <dd>{t("status", { status: subscription.status })}</dd>
          <dt>{subscription.auto_renew ? t("renewal") : t("ends_on")}</dt>
          <dd>{subscription.current_period_end ? format.dateTime(new Date(subscription.current_period_end), { dateStyle: "long" }) : "—"}</dd>
        </dl>
      ) : null}
      <div className="row wrapf mt32">
        <a className="btn" href={storeManagementUrl(channel)} target="_blank" rel="noopener noreferrer">
          {t("store_open", { channel })}
        </a>
        <form action={logout}>
          <button type="submit" className="btn ghost">
            {t("logout")}
          </button>
        </form>
      </div>
    </div>
  );
}
