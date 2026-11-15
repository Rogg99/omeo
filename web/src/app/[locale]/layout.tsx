import "../globals.css";

import type { Metadata, Viewport } from "next";
import { notFound } from "next/navigation";
import { NextIntlClientProvider } from "next-intl";
import { getMessages, getTranslations, setRequestLocale } from "next-intl/server";

import { JsonLd } from "@/components/JsonLd";
import { CookieConsent } from "@/components/layout/CookieConsent";
import { Footer } from "@/components/layout/Footer";
import { Header } from "@/components/layout/Header";
import { direction, isLocale, LOCALES } from "@/i18n/routing";
import { pageMetadata } from "@/lib/seo";
import source from "@/server/data/source";
import { env, siteOrigin } from "@/server/env";

import { accent, arabic, body, display } from "../fonts";

/**
 * Mise en page racine, par langue. La CSP à nonce impose un rendu à la requête : la page attend le
 * serveur (instant = false) ; les contenus de l'API restent en cache (`use cache`, 10 min + tags).
 */
export const instant = false;

/** Paramètre racine : une valeur par langue (exigé par Next pour un segment racine dynamique). */
export function generateStaticParams() {
  return LOCALES.map((locale) => ({ locale }));
}

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  // Couleurs de la barre du navigateur : --cream-50 et --bg-elev sombre (les métadonnées exigent une valeur)
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#fbf8f2" },
    { media: "(prefers-color-scheme: dark)", color: "#171613" },
  ],
};

export async function generateMetadata({ params }: LayoutProps<"/[locale]">): Promise<Metadata> {
  const { locale } = await params;
  if (!isLocale(locale)) return {};
  const t = await getTranslations({ locale, namespace: "web.meta" });
  return {
    metadataBase: new URL(siteOrigin),
    applicationName: "Omeo",
    title: { default: t("default_title"), template: t("title_template", { page: "%s" }) },
    ...pageMetadata({
      origin: siteOrigin,
      locale,
      path: "/",
      title: t("default_title"),
      description: t("default_description"),
      absoluteTitle: true,
    }),
    // Pas d'indexation des environnements de démonstration
    ...(source.demo ? { robots: { index: false, follow: false } } : {}),
  };
}

export default async function LocaleLayout({ children, params }: LayoutProps<"/[locale]">) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();
  setRequestLocale(locale);
  const [t, messages] = await Promise.all([getTranslations("web"), getMessages()]);
  // Seuls les textes de la page d'erreur (composant client) partent au navigateur.
  const clientMessages = {
    web: { error: (messages.web as Record<string, unknown>).error },
    common: { action: (messages.common as Record<string, unknown>).action },
  } as typeof messages;
  const fonts = [display.variable, body.variable, accent.variable, locale === "ar" ? arabic.variable : ""].join(" ");
  const analytics = env.ANALYTICS_PROVIDER === "none" ? undefined : env.ANALYTICS_PROVIDER;

  return (
    <html lang={locale} dir={direction(locale)} className={fonts}>
      <body>
        <NextIntlClientProvider messages={clientMessages}>
          <a className="skip" href="#main">
            {t("a11y.skip_to_content")}
          </a>
          {source.demo ? (
            <p className="demo-banner" role="note">
              {t("mock.banner")}
            </p>
          ) : null}
          <Header />
          <main id="main" tabIndex={-1}>
            {children}
          </main>
          <Footer />
          {analytics ? (
            <CookieConsent
              analytics={{ provider: analytics, siteId: env.ANALYTICS_SITE_ID, domain: new URL(siteOrigin).hostname }}
              labels={{
                title: t("cookie.title"),
                body: t("cookie.body"),
                accept: t("cookie.accept"),
                refuse: t("cookie.refuse"),
                more: t("cookie.customize"),
              }}
            />
          ) : null}
        </NextIntlClientProvider>
        <JsonLd
          data={{
            "@context": "https://schema.org",
            "@type": "Organization",
            name: "Omeo",
            url: siteOrigin,
            logo: `${siteOrigin}/icon.svg`,
            description: t("meta.org_description"),
          }}
        />
      </body>
    </html>
  );
}
