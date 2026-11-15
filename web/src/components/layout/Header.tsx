import { getLocale, getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { Logo } from "@/components/Logo";
import { LOCALE_NAMES, LOCALES, type Locale } from "@/i18n/routing";
import { currentPath, isCurrent } from "@/server/pathname";

/**
 * En-tête rendu entièrement sur le serveur : liens ordinaires et menus en <details> natifs
 * (clavier et lecteurs d'écran sans JavaScript). Aucun îlot client : rien à hydrater.
 */
export async function Header() {
  const [t, locale, path] = await Promise.all([getTranslations("web"), getLocale(), currentPath()]);
  const href = (p: string) => `/${locale}${p === "/" ? "" : p}`;
  const items = [
    { href: "/features", label: t("nav.features") },
    { href: "/pricing", label: t("nav.pricing") },
    { href: "/faq", label: t("nav.faq") },
    { href: "/contact", label: t("nav.contact") },
  ];
  const mobileItems = [...items, { href: "/subscription", label: t("nav.subscription") }, { href: "/#download", label: t("nav.download") }];

  return (
    <header className="nav">
      <div className="wrap">
        <a href={href("/")} className="home-link" aria-label={t("a11y.home")}>
          <Logo size={34} withText={false} />
          <span aria-hidden="true" style={{ font: "var(--weight-semibold) 1.3rem var(--font-display)" }}>
            omeo
          </span>
        </a>
        <nav className="links hide-m" aria-label={t("a11y.main_nav")}>
          {items.map((item) => (
            <a key={item.href} href={href(item.href)} aria-current={isCurrent(path, item.href) ? "page" : undefined}>
              {item.label}
            </a>
          ))}
        </nav>
        <span className="grow" />
        <details className="dropdown">
          <summary className="lang" aria-label={`${locale.toUpperCase()} · ${t("a11y.language", { language: LOCALE_NAMES[locale as Locale] })}`}>
            <Icon name="globe" />
            <span aria-hidden="true">{locale.toUpperCase()}</span>
          </summary>
          <ul className="menu" aria-label={t("a11y.choose_language")}>
            {LOCALES.map((l) => (
              <li key={l}>
                <a href={`/${l}${path === "/" ? "" : path}`} hrefLang={l} lang={l} aria-current={l === locale ? "true" : undefined}>
                  {LOCALE_NAMES[l]}
                </a>
              </li>
            ))}
          </ul>
        </details>
        <a className="btn sm ghost hide-m" href={href("/subscription")}>
          {t("nav.subscription")}
        </a>
        <a className="btn sm green nav-download" href={href("/#download")}>
          {t("nav.download")}
        </a>
        <details className="dropdown only-m">
          <summary className="lang" aria-label={t("a11y.open_menu")}>
            <Icon name="plus" />
          </summary>
          <nav className="mobile-panel" aria-label={t("a11y.main_nav")}>
            {mobileItems.map((item) => (
              <a key={item.href} href={href(item.href)} aria-current={isCurrent(path, item.href) ? "page" : undefined}>
                {item.label}
              </a>
            ))}
          </nav>
        </details>
      </div>
    </header>
  );
}
