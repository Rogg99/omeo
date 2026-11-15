import { notFound } from "next/navigation";
import { getTranslations } from "next-intl/server";

import { pageLocale } from "@/i18n/page";
import source from "@/server/data/source";
import { siteOrigin } from "@/server/env";
import { loadSubscription } from "@/server/subscription";

import { mockSetAutoRenew } from "../actions";

/** Retour accepté uniquement vers le site lui-même. */
function safeReturn(value: unknown, fallback: string): string {
  if (typeof value !== "string") return fallback;
  try {
    const url = new URL(value, siteOrigin);
    return url.origin === siteOrigin ? url.toString() : fallback;
  } catch {
    return fallback;
  }
}

/** Mode démo : remplace le portail de l'agrégateur (résiliation ou reprise du renouvellement). */
export default async function MockPortalPage({ params, searchParams }: PageProps<"/[locale]/subscription/mock-portal">) {
  const locale = await pageLocale(params);
  if (!source.demo) notFound();
  const page = await loadSubscription(locale);
  const [t, query] = await Promise.all([getTranslations("web.mock"), searchParams]);
  const back = safeReturn(query.return, `${siteOrigin}/${locale}/subscription/manage`);
  const subscription = "state" in page ? page.state.subscription : null;

  return (
    <div className="card">
      <span className="tag orange">{t("banner")}</span>
      <h1 className="h2 mt16">{t("portal_title")}</h1>
      <p className="muted mt8">{t("portal_lead")}</p>
      {subscription ? (
        <form action={mockSetAutoRenew} className="mt24">
          <input type="hidden" name="return" value={back} />
          <input type="hidden" name="auto_renew" value={subscription.auto_renew ? "false" : "true"} />
          <p className="mt8">
            <b>{subscription.plan_name}</b>
          </p>
          <button type="submit" className={`btn mt16 ${subscription.auto_renew ? "danger" : "green"}`}>
            {subscription.auto_renew ? t("portal_cancel") : t("portal_resume")}
          </button>
        </form>
      ) : null}
      <a className="btn ghost mt24" href={back}>
        {t("portal_back")}
      </a>
    </div>
  );
}
