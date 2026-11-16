import Link from "next/link";
import { getTranslations } from "next-intl/server";

export default async function NotFound() {
  const t = await getTranslations("admin");
  return (
    <main id="main" className="page" style={{ margin: "10vh auto", maxWidth: 560, textAlign: "center" }}>
      <div className="stack" style={{ alignItems: "center" }}>
        <h1>{t("not_found.title")}</h1>
        <p className="muted">{t("not_found.body")}</p>
        <Link href="/" className="btn primary">
          {t("forbidden.home")}
        </Link>
      </div>
    </main>
  );
}
