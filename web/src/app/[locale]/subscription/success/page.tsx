import NextLink from "next/link";
import { redirect } from "next/navigation";
import { getFormatter, getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { Link } from "@/i18n/navigation";
import { pageLocale } from "@/i18n/page";
import { sessionEmail } from "@/server/session";
import { loadSubscription } from "@/server/subscription";

import { ActivationPoller } from "./ActivationPoller";

/** Retour en succès : attend l'activation par le webhook, puis récapitule l'abonnement. */
export default async function SuccessPage({ params }: PageProps<"/[locale]/subscription/success">) {
  const locale = await pageLocale(params);
  const page = await loadSubscription(locale);
  const [t, format, email] = await Promise.all([getTranslations("web.subscription"), getFormatter(), sessionEmail()]);
  if ("state" in page && page.state.can_manage === "store") redirect(`/${locale}/subscription/store`);

  const subscription = "state" in page && page.state.can_manage === "web" ? page.state.subscription : null;
  if (!subscription) {
    return (
      <div className="card center" aria-busy="true">
        <h1 className="h2">{t("activating_title")}</h1>
        <p className="muted mt16">{t("activating_lead")}</p>
        <div style={{ display: "grid", placeItems: "center" }}>
          <ActivationPoller slowMessage={t("activation_slow")} checkAgain={t("check_again")} />
        </div>
      </div>
    );
  }

  const date = subscription.current_period_end ? format.dateTime(new Date(subscription.current_period_end), { dateStyle: "long" }) : "—";
  return (
    <div className="card" role="status">
      <span className="ib">
        <Icon name="crown" />
      </span>
      <h1 className="h2 mt16">{t("success_title")}</h1>
      <p className="lead mt16">{t("success_lead")}</p>
      <dl className="kv mt24">
        <dt>{t("offer")}</dt>
        <dd>{subscription.plan_name}</dd>
        <dt>{subscription.auto_renew ? t("renewal") : t("ends_on")}</dt>
        <dd>{date}</dd>
        {email ? (
          <>
            <dt>{t("receipt")}</dt>
            <dd>{t("receipt_sent", { email })}</dd>
          </>
        ) : null}
      </dl>
      <div className="row wrapf mt32">
        <NextLink className="btn green" href="/download" prefetch={false}>
          {t("open_app")}
        </NextLink>
        <Link className="btn ghost" href="/subscription/manage">
          {t("manage")}
        </Link>
      </div>
    </div>
  );
}
