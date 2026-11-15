import { getLocale, getTranslations } from "next-intl/server";

import { Logo } from "@/components/Logo";
import { Link } from "@/i18n/navigation";
import { LOCALE_NAMES, type Locale } from "@/i18n/routing";

import { LanguageSwitcher } from "./LanguageSwitcher";
import { MobileMenu } from "./MobileMenu";
import { NavLinks } from "./NavLinks";

export async function Header() {
  const [t, locale] = await Promise.all([getTranslations("web"), getLocale()]);
  const items = [
    { href: "/features", label: t("nav.features") },
    { href: "/pricing", label: t("nav.pricing") },
    { href: "/faq", label: t("nav.faq") },
    { href: "/contact", label: t("nav.contact") },
  ];
  return (
    <header className="nav">
      <div className="wrap">
        <Link href="/" className="home-link" aria-label={t("a11y.home")}>
          <Logo size={34} withText={false} />
          <span aria-hidden="true" style={{ font: "var(--weight-semibold) 1.3rem var(--font-display)" }}>
            omeo
          </span>
        </Link>
        <nav className="links hide-m" aria-label={t("a11y.main_nav")}>
          <NavLinks items={items} />
        </nav>
        <span className="grow" />
        <LanguageSwitcher
          label={t("a11y.language", { language: LOCALE_NAMES[locale as Locale] })}
          chooseLabel={t("a11y.choose_language")}
        />
        <Link className="btn sm ghost hide-m" href="/subscription">
          {t("nav.subscription")}
        </Link>
        <Link className="btn sm green" href="/#download">
          {t("nav.download")}
        </Link>
        <MobileMenu
          items={[...items, { href: "/subscription", label: t("nav.subscription") }]}
          openLabel={t("a11y.open_menu")}
          closeLabel={t("a11y.close_menu")}
          navLabel={t("a11y.main_nav")}
        />
      </div>
    </header>
  );
}
