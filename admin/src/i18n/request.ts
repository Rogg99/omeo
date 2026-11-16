import { getRequestConfig } from "next-intl/server";

/**
 * Langue de l'interface admin : français. La structure est prête pour l'anglais (messages/en.json
 * généré par `pnpm --dir shared build:i18n`) : il suffira de lire la préférence ici.
 */
export const ADMIN_LOCALE = "fr";

export default getRequestConfig(async () => ({
  locale: ADMIN_LOCALE,
  timeZone: "UTC",
  messages: (await import(`../../messages/${ADMIN_LOCALE}.json`)).default,
}));
