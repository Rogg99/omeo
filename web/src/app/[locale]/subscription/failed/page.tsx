import { getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { Link } from "@/i18n/navigation";
import { pageLocale } from "@/i18n/page";
import { rich } from "@/i18n/rich";
import { requireSession } from "@/server/subscription";

/** Retour en échec ou abandon (cancel_url?status=failed|canceled) : rien n'a été débité. */
export default async function FailedPage({ params, searchParams }: PageProps<"/[locale]/subscription/failed">) {
  const locale = await pageLocale(params);
  await requireSession(locale);
  const [t, query] = await Promise.all([getTranslations("web.subscription"), searchParams]);
  const canceled = query.status === "canceled";

  return (
    <div className="card">
      <span className="ib orange">
        <Icon name="card" />
      </span>
      <h1 className="h2 mt16">{t("failed_title")}</h1>
      <p className="note warn mt24" role="status">
        <Icon name="info" />
        <span>{t.rich(canceled ? "canceled_body" : "failed_body", rich)}</span>
      </p>
      <div className="row wrapf mt32">
        <Link className="btn green" href="/subscription/plan">
          {t("retry")}
        </Link>
        <Link className="btn ghost" href="/pricing">
          {t("change_plan")}
        </Link>
      </div>
    </div>
  );
}
