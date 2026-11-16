import Link from "next/link";
import { getTranslations } from "next-intl/server";
import type { ReactNode } from "react";

type Crumb = { href: string; label: string };

/** En-tête de page (composant serveur) (previews/admin : fil d'Ariane, titre, sous-titre, actions). */
export async function PageHeader({
  title,
  subtitle,
  crumbs,
  actions,
}: {
  title: ReactNode;
  subtitle?: ReactNode;
  crumbs?: Crumb[];
  actions?: ReactNode;
}) {
  const t = await getTranslations("admin.a11y");
  return (
    <>
      {crumbs?.length ? (
        <nav className="crumbs" aria-label={t("breadcrumbs")}>
          {crumbs.map((c) => (
            <span key={c.href} className="row" style={{ gap: 6 }}>
              <Link href={c.href}>{c.label}</Link>
              <span aria-hidden="true">/</span>
            </span>
          ))}
        </nav>
      ) : null}
      <div className="ph">
        <div>
          <h1>{title}</h1>
          {subtitle ? <div className="sub">{subtitle}</div> : null}
        </div>
        {actions ? <div className="actions">{actions}</div> : null}
      </div>
    </>
  );
}
