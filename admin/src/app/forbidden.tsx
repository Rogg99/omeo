import Link from "next/link";
import { getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";

/** Écran « Accès refusé » : permission absente (forbidden()) ou 403 `forbidden_role` de l'API. */
export default async function Forbidden() {
  const t = await getTranslations("admin.forbidden");
  return (
    <main id="main" className="page" style={{ margin: "10vh auto", maxWidth: 560, textAlign: "center" }}>
      <div className="stack" style={{ alignItems: "center" }}>
        <span className="av lg" aria-hidden="true">
          <Icon name="lock" />
        </span>
        <h1>{t("title")}</h1>
        <p className="muted">{t("body")}</p>
        <Link href="/" className="btn primary">
          {t("home")}
        </Link>
      </div>
    </main>
  );
}
