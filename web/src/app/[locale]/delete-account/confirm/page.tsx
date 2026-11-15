import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { Link } from "@/i18n/navigation";
import { pageLocale } from "@/i18n/page";

import { DeletionConfirmForm } from "../DeletionForms";

export const metadata: Metadata = { robots: { index: false, follow: false }, referrer: "no-referrer" };

/** Lien reçu par email : la suppression ne démarre qu'après un clic explicite (double confirmation). */
export default async function ConfirmDeletionPage({ params, searchParams }: PageProps<"/[locale]/delete-account/confirm">) {
  await pageLocale(params);
  const [t, query] = await Promise.all([getTranslations("web.deletion"), searchParams]);
  const token = typeof query.token === "string" ? query.token : undefined;
  const retry = (
    <Link className="btn ghost" href="/delete-account">
      {t("confirm_retry")}
    </Link>
  );

  return (
    <div className="narrow" style={{ paddingBlock: "var(--space-16) var(--section)" }}>
      <h1 className="h2">{t("confirm_title")}</h1>
      {token ? (
        <>
          <p className="note warn mt24">
            <Icon name="alert" />
            <span>{t("confirm_body")}</span>
          </p>
          <div className="mt24">
            <DeletionConfirmForm
              token={token}
              labels={{
                submit: t("confirm_submit"),
                sending: t("sending"),
                invalid: t("confirm_invalid"),
                retry,
                doneTitle: t("done_title"),
                doneBody: t("done_body"),
              }}
            />
          </div>
        </>
      ) : (
        <div className="stack mt24">
          <p className="note danger" role="alert">
            <Icon name="alert" />
            <span>{t("confirm_missing")}</span>
          </p>
          {retry}
        </div>
      )}
    </div>
  );
}
