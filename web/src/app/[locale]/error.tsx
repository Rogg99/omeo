"use client";

import { useTranslations } from "next-intl";

/** Erreur inattendue pendant le rendu : message traduit et nouvel essai, sans détail technique. */
export default function ErrorPage({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  const t = useTranslations();
  return (
    <section className="section narrow center" role="alert">
      <h1 className="h2">{t("web.error.title")}</h1>
      <p className="lead mt16">{t("web.error.body")}</p>
      <button type="button" className="btn mt32" onClick={reset}>
        {t("common.action.retry")}
      </button>
    </section>
  );
}
