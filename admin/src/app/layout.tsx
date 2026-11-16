import "./globals.css";

import type { Metadata, Viewport } from "next";
import { cookies } from "next/headers";
import { NextIntlClientProvider } from "next-intl";
import { getMessages, getTranslations } from "next-intl/server";

import { CsrfProvider } from "@/components/providers/StaffProvider";
import { ToastProvider } from "@/components/providers/ToastProvider";
import { COOKIES } from "@/server/session-cookies";

import { body, display } from "./fonts";

export async function generateMetadata(): Promise<Metadata> {
  const t = await getTranslations("admin.meta");
  return {
    title: { default: t("title"), template: t("title_template", { page: "%s" }) },
    robots: { index: false, follow: false },
  };
}

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#f6f1e7" },
    { media: "(prefers-color-scheme: dark)", color: "#12110e" },
  ],
};

/**
 * Mise en page racine. Rendue à chaque requête (cookies) : la CSP à nonce et le jeton CSRF sont
 * propres à la requête. Les messages de l'interface sont tous envoyés au client (admin interne).
 */
export default async function RootLayout({ children }: LayoutProps<"/">) {
  const [messages, t, store] = await Promise.all([getMessages(), getTranslations(), cookies()]);
  const csrf = store.get(COOKIES.csrf)?.value ?? "";

  return (
    <html lang="fr" dir="ltr" className={`${display.variable} ${body.variable}`}>
      <body>
        <NextIntlClientProvider messages={messages}>
          <CsrfProvider token={csrf}>
            <ToastProvider closeLabel={t("common.action.close")}>
              <a className="skip" href="#main">
                {t("admin.a11y.skip_to_content")}
              </a>
              {children}
            </ToastProvider>
          </CsrfProvider>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
