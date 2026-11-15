import { notFound } from "next/navigation";
import { getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { Link } from "@/i18n/navigation";
import { pageLocale } from "@/i18n/page";
import source from "@/server/data/source";

import { mockCompleteCheckout } from "../actions";

/** Mode démo : remplace la page de paiement de l'agrégateur (succès, échec ou abandon). */
export default async function MockCheckoutPage({ params, searchParams }: PageProps<"/[locale]/subscription/mock-checkout">) {
  const locale = await pageLocale(params);
  if (!source.demo) notFound();
  const [t, query] = await Promise.all([getTranslations("web.mock"), searchParams]);
  const id = typeof query.session === "string" ? query.session : "";
  const checkout = source.demo.checkoutSession(id, locale);

  if (!checkout || checkout.expired) {
    return (
      <div className="card">
        <h1 className="h2">{t("checkout_title")}</h1>
        <p className="note warn mt24" role="alert">
          <Icon name="alert" />
          <span>{t("checkout_expired")}</span>
        </p>
        <Link className="btn mt24" href="/subscription/plan">
          {(await getTranslations("web.subscription"))("change_plan")}
        </Link>
      </div>
    );
  }

  const outcomes = [
    ["success", t("checkout_success"), "btn green block"],
    ["failure", t("checkout_failure"), "btn danger block"],
    ["abandon", t("checkout_abandon"), "btn ghost block"],
  ] as const;

  return (
    <div className="card">
      <span className="tag orange">{t("banner")}</span>
      <h1 className="h2 mt16">{t("checkout_title")}</h1>
      <p className="muted mt8">{t("checkout_lead")}</p>
      <dl className="kv mt24">
        <dt>{checkout.planName}</dt>
        <dd>{t("checkout_amount", { amount: checkout.amount.formatted ?? "" })}</dd>
      </dl>
      <div className="stack mt32">
        {outcomes.map(([outcome, label, className]) => (
          <form key={outcome} action={mockCompleteCheckout}>
            <input type="hidden" name="session" value={checkout.id} />
            <input type="hidden" name="outcome" value={outcome} />
            <button type="submit" className={className}>
              {label}
            </button>
          </form>
        ))}
      </div>
    </div>
  );
}
