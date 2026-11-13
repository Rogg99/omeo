import { hasLocale } from "next-intl";
import { getRequestConfig } from "next-intl/server";

import { routing } from "./routing";

export default getRequestConfig(async ({ requestLocale }) => {
  const requested = await requestLocale;
  const locale = hasLocale(routing.locales, requested) ? requested : routing.defaultLocale;
  return {
    locale,
    // Fichiers générés par `pnpm --dir shared build:i18n`, repli déjà appliqué (langue → en → fr)
    messages: (await import(`../../messages/${locale}.json`)).default,
  };
});
