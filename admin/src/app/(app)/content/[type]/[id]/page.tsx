import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getTranslations } from "next-intl/server";

import { ContentEditor } from "@/components/content/ContentEditor";
import { PageHeader } from "@/components/ui/PageHeader";
import { ContentStatusTag } from "@/components/ui/Tags";
import { isContentType } from "@/lib/content-types";
import { formatRelative } from "@/lib/format";
import { load, requirePermission } from "@/server/auth";
import source from "@/server/data/source";

export async function generateMetadata({ params }: PageProps<"/content/[type]/[id]">): Promise<Metadata> {
  const { type } = await params;
  return { title: isContentType(type) ? (await getTranslations("admin.content"))(`type_${type}`) : undefined };
}

/** Édition d'un contenu : langue par langue, workflow, historique des versions, verrou optimiste. */
export default async function ContentPage({ params }: PageProps<"/content/[type]/[id]">) {
  const { type, id } = await params;
  if (!isContentType(type)) notFound();
  const { ctx } = await requirePermission("content.view");
  const [item, revisions, t] = await Promise.all([
    load(source.content.get(type, id, ctx)),
    load(source.content.revisions(type, id, ctx)),
    getTranslations("admin.content"),
  ]);
  return (
    <div className="page">
      <PageHeader
        crumbs={[
          { href: "/content", label: t("title") },
          { href: `/content/${type}`, label: t(`type_${type}`) },
        ]}
        title={item.title}
        subtitle={
          <span className="row">
            <ContentStatusTag status={item.status} />
            <span>{t("version_meta", { version: item.version, when: formatRelative(item.updated_at), by: item.updated_by ?? "—" })}</span>
          </span>
        }
      />
      <ContentEditor key={`${item.id}-${item.version}`} type={type} initial={item} initialData={item.data} revisions={revisions} />
    </div>
  );
}
