import { redirect } from "next/navigation";
import { getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { pageLocale } from "@/i18n/page";
import { errorMessage } from "@/server/forms";
import { loadSubscription, stepFor } from "@/server/subscription";

/** Entrée de la page Abonnement : renvoie vers l'étape qui correspond à l'état du compte. */
export default async function SubscriptionPage({ params, searchParams }: PageProps<"/[locale]/subscription">) {
  const locale = await pageLocale(params);
  const page = await loadSubscription(locale);
  if ("state" in page) {
    const step = stepFor(page.state);
    const plan = (await searchParams).plan;
    const query = step === "plan" && typeof plan === "string" ? `?plan=${encodeURIComponent(plan)}` : "";
    redirect(`/${locale}/subscription/${step}${query}`);
  }
  const t = await getTranslations("web.subscription");
  return (
    <>
      <h1 className="h2">{t("manage_title")}</h1>
      <p className="note danger mt24" role="alert">
        <Icon name="alert" />
        <span>{await errorMessage(page.problem.code)}</span>
      </p>
    </>
  );
}
