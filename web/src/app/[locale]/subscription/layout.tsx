import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";

import { metadataLocale } from "@/i18n/page";

/** Espace personnel : jamais indexé, jamais mis en cache. */
export async function generateMetadata({ params }: LayoutProps<"/[locale]/subscription">): Promise<Metadata> {
  const locale = await metadataLocale(params);
  if (!locale) return {};
  const t = await getTranslations({ locale, namespace: "web.meta" });
  return { title: t("subscription_title"), robots: { index: false, follow: false } };
}

export default function SubscriptionLayout({ children }: LayoutProps<"/[locale]/subscription">) {
  return (
    <div className="narrow" style={{ paddingBlock: "var(--space-12) var(--section)", maxInlineSize: 640 }}>
      {children}
    </div>
  );
}
