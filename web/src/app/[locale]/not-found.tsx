import { getTranslations } from "next-intl/server";

import { Link } from "@/i18n/navigation";

export default async function NotFound() {
  const t = await getTranslations("web.not_found");
  return (
    <section className="section narrow center">
      <p className="eyebrow">404</p>
      <h1 className="h2 mt16">{t("title")}</h1>
      <p className="lead mt16">{t("body")}</p>
      <Link className="btn mt32" href="/">
        {t("home")}
      </Link>
    </section>
  );
}
