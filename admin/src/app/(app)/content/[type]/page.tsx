import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";
import { PageHeader } from "@/components/ui/PageHeader";
import { CONTENT_STATUSES, isContentType } from "@/lib/content-types";
import { LOCALES } from "@/lib/locales";
import { oneOf, ordering, pageOf, str, type RawParams } from "@/lib/search-params";
import { load, requirePermission } from "@/server/auth";
import source from "@/server/data/source";

import { ContentTable } from "./ContentTable";

export async function generateMetadata({ params }: PageProps<"/content/[type]">): Promise<Metadata> {
  const { type } = await params;
  return { title: isContentType(type) ? (await getTranslations("admin.content"))(`type_${type}`) : undefined };
}

/** Liste d'un type : recherche, statut et langue manquante dans l'URL. */
export default async function ContentListPage({ params, searchParams }: PageProps<"/content/[type]">) {
  const { type } = await params;
  if (!isContentType(type)) notFound();
  const { ctx, can } = await requirePermission("content.view");
  const query = (await searchParams) as RawParams;
  const t = await getTranslations("admin.content");
  const data = await load(
    source.content.list(
      type,
      {
        ...pageOf(query),
        q: str(query, "q"),
        status: oneOf(query, "status", CONTENT_STATUSES),
        missing_locale: oneOf(query, "missing_locale", LOCALES),
        ordering: ordering(query, ["updated_at", "title"]),
      },
      ctx,
    ),
  );
  const missing = data.results.filter((r) => r.missing_locales.length > 0).length;

  return (
    <div className="page">
      <PageHeader
        crumbs={[{ href: "/content", label: t("title") }]}
        title={t(`type_${type}`)}
        subtitle={t("list_subtitle", { count: data.count, missing })}
        actions={
          can("content.edit") ? (
            <Link href={`/content/${type}/new`} className="btn primary">
              <Icon name="plus" />
              {t("new")}
            </Link>
          ) : null
        }
      />
      <ContentTable type={type} rows={data.results} total={data.count} page={data.page} pageSize={data.page_size} />
    </div>
  );
}
