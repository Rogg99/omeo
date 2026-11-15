import { randomUUID } from "node:crypto";

import type { Metadata } from "next";
import { connection } from "next/server";
import { getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { Link } from "@/i18n/navigation";
import { metadataLocale, pageLocale } from "@/i18n/page";
import { rich } from "@/i18n/rich";
import { pageMetadata } from "@/lib/seo";
import source from "@/server/data/source";
import { env, siteOrigin } from "@/server/env";

import { ContactForm } from "./ContactForm";
import { CONTACT_CATEGORIES, MESSAGE_MAX } from "./schema";

export async function generateMetadata({ params }: PageProps<"/[locale]/contact">): Promise<Metadata> {
  const locale = await metadataLocale(params);
  if (!locale) return {};
  const t = await getTranslations({ locale, namespace: "web.meta" });
  return pageMetadata({ origin: siteOrigin, locale, path: "/contact", title: t("contact_title"), description: t("contact_description") });
}

export default async function ContactPage({ params }: PageProps<"/[locale]/contact">) {
  const locale = await pageLocale(params);
  const t = await getTranslations("web.contact");
  // Clé d'idempotence propre à chaque affichage du formulaire : rendu à la requête.
  await connection();
  const captcha = source.captchaRequired && env.TURNSTILE_SITE_KEY ? { siteKey: env.TURNSTILE_SITE_KEY, locale } : undefined;

  return (
    <div className="wrap grid g2" style={{ gap: "var(--space-12)", paddingBlock: "var(--space-16) var(--section)", alignItems: "start" }}>
      <div>
        <p className="eyebrow">{t("eyebrow")}</p>
        <h1 className="h1 mt16">{t.rich("title", rich)}</h1>
        <p className="lead mt24">{t("lead")}</p>
        <div className="stack mt32">
          <div className="row" style={{ alignItems: "flex-start" }}>
            <span className="ib">
              <Icon name="help" />
            </span>
            <div>
              <h2 className="h3">{t("faq_title")}</h2>
              <p className="muted">{t.rich("faq_body", { link: (c) => <Link href="/faq">{c}</Link> })}</p>
            </div>
          </div>
          <div className="row" style={{ alignItems: "flex-start" }}>
            <span className="ib orange">
              <Icon name="phone" />
            </span>
            <div>
              <h2 className="h3">{t("app_title")}</h2>
              <p className="muted">{t("app_body")}</p>
            </div>
          </div>
        </div>
      </div>
      <ContactForm
        locale={locale}
        idempotencyKey={randomUUID()}
        messageMax={MESSAGE_MAX}
        captcha={captcha}
        categories={CONTACT_CATEGORIES.map((value) => ({ value, label: t("category_name", { category: value }) }))}
        labels={{
          name: t("name"),
          email: t("email"),
          category: t("category"),
          subject: t("subject"),
          message: t("message"),
          consent: t.rich("consent", { link: (c) => <Link href="/legal/privacy">{c}</Link> }),
          submit: t("submit"),
          sending: t("sending"),
          successTitle: t("success_title"),
          successBody: t.raw("success_body") as string,
          newMessage: t("new_message"),
        }}
      />
    </div>
  );
}
