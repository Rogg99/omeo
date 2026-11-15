import { cacheLife } from "next/cache";
import { getLocale, getTranslations } from "next-intl/server";

import { Logo } from "@/components/Logo";
import { StoreButtons } from "@/components/StoreButtons";
import { LOCALE_NAMES, LOCALES } from "@/i18n/routing";
import { env } from "@/server/env";

import { ManageCookiesButton } from "./CookieConsent";

const LEGAL_KINDS = ["terms", "privacy", "cookies", "legal_notice"] as const;

/** Année du copyright, figée en cache pour la journée (pas de calcul d'heure pendant le prérendu). */
async function currentYear(): Promise<number> {
  "use cache";
  cacheLife("days");
  return new Date().getFullYear();
}

export async function Footer() {
  const [t, year, locale] = await Promise.all([getTranslations("web"), currentYear(), getLocale()]);
  // Liens ordinaires : le pied de page n'envoie aucun composant client au navigateur
  const href = (path: string) => `/${locale}${path}`;
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
                <a href={href("/features")}>{t("nav.features")}</a>
              </li>
              <li>
                <a href={href("/pricing")}>{t("nav.pricing")}</a>
              </li>
              <li>
                <a href={href("/subscription")}>{t("nav.subscription")}</a>
              </li>
              <li>
                <a href={href("/faq")}>{t("nav.faq")}</a>
              </li>
            </ul>
          </nav>
          <nav aria-labelledby="foot-help">
            <h2 id="foot-help">{t("footer.help")}</h2>
            <ul>
              <li>
                <a href={href("/contact")}>{t("nav.contact")}</a>
              </li>
              <li>
                <a href={href("/delete-account")}>{t("footer.delete_account")}</a>
              </li>
              <li>
                <a href={href("/credits")}>{t("footer.credits")}</a>
              </li>
            </ul>
          </nav>
          <nav aria-labelledby="foot-legal">
            <h2 id="foot-legal">{t("footer.legal")}</h2>
            <ul>
              {LEGAL_KINDS.map((kind) => (
                <li key={kind}>
                  <a href={href(`/legal/${kind}`)}>{t(`legal_kind.${kind}`)}</a>
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
          <span>{t("footer.copyright", { year })}</span>
          <span className="grow" />
          <ul className="row wrapf" aria-label={t("a11y.choose_language")} style={{ display: "flex" }}>
            {LOCALES.map((l) => (
              <li key={l}>
                <a href={`/${l}`} hrefLang={l} lang={l}>
                  {LOCALE_NAMES[l]}
                </a>
              </li>
            ))}
          </ul>
        </div>
        <p className="xs mt16">{t("footer.disclaimer")}</p>
      </div>
    </footer>
  );
}
