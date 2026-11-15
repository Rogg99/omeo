import { getTranslations } from "next-intl/server";

import { Logo } from "@/components/Logo";
import { StoreButtons } from "@/components/StoreButtons";
import { Link } from "@/i18n/navigation";
import { LOCALE_NAMES, LOCALES } from "@/i18n/routing";
import { env } from "@/server/env";

import { ManageCookiesButton } from "./CookieConsent";

const LEGAL_KINDS = ["terms", "privacy", "cookies", "legal_notice"] as const;

export async function Footer() {
  const t = await getTranslations("web");
  const analytics = env.ANALYTICS_PROVIDER !== "none";
  return (
    <footer className="foot">
      <div className="wrap">
        <div className="foot-grid">
          <div>
            <span className="logo">
              <Logo size={36} withText={false} />
            </span>
            <p className="mt16" style={{ maxInlineSize: 320 }}>
              {t("footer.tagline")}
            </p>
            <div className="mt24">
              <StoreButtons raised />
            </div>
          </div>
          <nav aria-labelledby="foot-product">
            <h2 id="foot-product">{t("footer.product")}</h2>
            <ul>
              <li>
                <Link href="/features">{t("nav.features")}</Link>
              </li>
              <li>
                <Link href="/pricing">{t("nav.pricing")}</Link>
              </li>
              <li>
                <Link href="/subscription">{t("nav.subscription")}</Link>
              </li>
              <li>
                <Link href="/faq">{t("nav.faq")}</Link>
              </li>
            </ul>
          </nav>
          <nav aria-labelledby="foot-help">
            <h2 id="foot-help">{t("footer.help")}</h2>
            <ul>
              <li>
                <Link href="/contact">{t("nav.contact")}</Link>
              </li>
              <li>
                <Link href="/delete-account">{t("footer.delete_account")}</Link>
              </li>
              <li>
                <Link href="/credits">{t("footer.credits")}</Link>
              </li>
            </ul>
          </nav>
          <nav aria-labelledby="foot-legal">
            <h2 id="foot-legal">{t("footer.legal")}</h2>
            <ul>
              {LEGAL_KINDS.map((kind) => (
                <li key={kind}>
                  <Link href={`/legal/${kind}`}>{t(`legal_kind.${kind}`)}</Link>
                </li>
              ))}
              {analytics ? (
                <li>
                  <ManageCookiesButton label={t("footer.manage_cookies")} />
                </li>
              ) : null}
            </ul>
          </nav>
        </div>
        <div className="bottom">
          <span>{t("footer.copyright", { year: new Date().getFullYear() })}</span>
          <span className="grow" />
          <ul className="row wrapf" aria-label={t("a11y.choose_language")} style={{ display: "flex" }}>
            {LOCALES.map((l) => (
              <li key={l}>
                <Link href="/" locale={l} hrefLang={l} lang={l}>
                  {LOCALE_NAMES[l]}
                </Link>
              </li>
            ))}
          </ul>
        </div>
        <p className="xs mt16">{t("footer.disclaimer")}</p>
      </div>
    </footer>
  );
}
