import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";

import { PageHeader } from "@/components/ui/PageHeader";
import { isoDate, pageOf, str, type RawParams } from "@/lib/search-params";
import { load, requirePermission } from "@/server/auth";
import source from "@/server/data/source";

import { AuditTable } from "./AuditTable";

export async function generateMetadata(): Promise<Metadata> {
  return { title: (await getTranslations("admin.nav"))("audit") };
}

/** Journal d'audit (ajout seul) : qui, quoi, quand, avant et après. Filtres dans l'URL. */
export default async function AuditPage({ searchParams }: PageProps<"/audit">) {
  const { ctx } = await requirePermission("audit.view");
  const params = (await searchParams) as RawParams;
  const t = await getTranslations("admin.audit");
  const data = await load(
    source.audit.list(
      {
        ...pageOf(params),
        action: str(params, "action", 80),
        target_type: str(params, "target_type", 40),
        target_id: str(params, "target_id", 80),
        from: isoDate(params, "from"),
        to: isoDate(params, "to"),
      },
      ctx,
    ),
  );
  return (
    <div className="page">
      <PageHeader title={t("title")} subtitle={t("subtitle")} />
      <AuditTable rows={data.results} total={data.count} page={data.page} pageSize={data.page_size} />
    </div>
  );
}
