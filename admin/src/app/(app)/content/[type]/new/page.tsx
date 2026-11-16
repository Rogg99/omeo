import { notFound } from "next/navigation";
import { getTranslations } from "next-intl/server";

import { ContentEditor } from "@/components/content/ContentEditor";
import { PageHeader } from "@/components/ui/PageHeader";
import { emptyData } from "@/lib/content-schema";
import { isContentType } from "@/lib/content-types";
import { requirePermission } from "@/server/auth";

/** Nouveau contenu : créé en brouillon. */
export default async function NewContentPage({ params }: PageProps<"/content/[type]/new">) {
  const { type } = await params;
  if (!isContentType(type)) notFound();
  await requirePermission("content.edit");
  const t = await getTranslations("admin.content");
  return (
    <div className="page">
      <PageHeader
        crumbs={[
          { href: "/content", label: t("title") },
          { href: `/content/${type}`, label: t(`type_${type}`) },
        ]}
        title={t("new_title", { type: t(`type_${type}`) })}
      />
      <ContentEditor type={type} initial={null} initialData={emptyData(type)} />
    </div>
  );
}
