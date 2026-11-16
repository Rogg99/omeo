"use client";

import { useTranslations } from "next-intl";
import { useEffect } from "react";

/** Erreur inattendue d'un rendu (API indisponible, 500…). Aucun détail technique n'est affiché. */
export default function ErrorPage({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  const t = useTranslations();
  useEffect(() => {
    console.error(error);
  }, [error]);
  return (
    <main id="main" className="page" style={{ margin: "10vh auto", maxWidth: 560, textAlign: "center" }}>
      <div className="stack" style={{ alignItems: "center" }} role="alert">
        <h1>{t("admin.error.title")}</h1>
        <p className="muted">{t("admin.error.body")}</p>
        {error.digest ? <p className="faint small">{t("admin.error.reference", { code: error.digest })}</p> : null}
        <button type="button" className="btn primary" onClick={reset}>
          {t("common.action.retry")}
        </button>
      </div>
    </main>
  );
}
