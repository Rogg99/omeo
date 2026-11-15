import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { metadataLocale, pageLocale } from "@/i18n/page";
import { rich } from "@/i18n/rich";
import { pageMetadata } from "@/lib/seo";
import source from "@/server/data/source";
import { env, siteOrigin } from "@/server/env";

import { DeletionRequestForm } from "./DeletionForms";

export async function generateMetadata({ params }: PageProps<"/[locale]/delete-account">): Promise<Metadata> {
  const locale = await metadataLocale(params);
  if (!locale) return {};
  const t = await getTranslations({ locale, namespace: "web.meta" });
  return pageMetadata({ origin: siteOrigin, locale, path: "/delete-account", title: t("deletion_title"), description: t("deletion_description") });
}

/** Page exigée par Google Play : demande de suppression sans l'app, confirmée par email. */
export default async function DeleteAccountPage({ params }: PageProps<"/[locale]/delete-account">) {
  const locale = await pageLocale(params);
  const [t, tm] = await Promise.all([getTranslations("web.deletion"), getTranslations("web.mock")]);
  const captcha = source.captchaRequired && env.TURNSTILE_SITE_KEY ? { siteKey: env.TURNSTILE_SITE_KEY, locale } : undefined;

  return (
    <div className="narrow" style={{ paddingBlock: "var(--space-16) var(--section)" }}>
      <p className="eyebrow">{t("eyebrow")}</p>
      <h1 className="h2 mt16">{t("title")}</h1>
      <p className="lead mt16">{t.rich("lead", rich)}</p>

      <div className="grid g2 mt32">
        <section className="card" aria-labelledby="deleted-title">
          <h2 id="deleted-title" className="h3">
            {t("deleted_title")}
          </h2>
          <ul className="stack mt16" style={{ listStyle: "none", padding: 0, gap: "var(--space-2)" }}>
            {([1, 2, 3, 4] as const).map((n) => (
              <li key={n} className="row">
                <Icon name="x" />
                {t(`deleted${n}`)}
              </li>
            ))}
          </ul>
          <p className="small muted mt16">{t("deleted_note")}</p>
        </section>
        <section className="card" aria-labelledby="kept-title">
          <h2 id="kept-title" className="h3">
            {t("kept_title")}
          </h2>
          <ul className="stack mt16" style={{ listStyle: "none", padding: 0, gap: "var(--space-2)" }}>
            {([1, 2] as const).map((n) => (
              <li key={n} className="row">
                <Icon name="lock" />
                {t(`kept${n}`)}
              </li>
            ))}
          </ul>
          <p className="small muted mt16">{t("kept_note")}</p>
        </section>
      </div>

      <p className="note warn mt24">
        <Icon name="alert" />
        <span>{t("store_warning")}</span>
      </p>

      <div className="mt32">
        <DeletionRequestForm
          captcha={captcha}
          labels={{
            title: t("form_title"),
            email: t("email"),
            note: t("form_note"),
            submit: t("submit"),
            sending: t("sending"),
            sentTitle: t("sent_title"),
            sentBody: t.raw("sent_body") as string,
            demoLink: tm("deletion_link"),
          }}
        />
      </div>
    </div>
  );
}
