import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";

import { PageHeader } from "@/components/ui/PageHeader";
import { TIERS, USER_STATUSES } from "@/lib/domain";
import { oneOf, ordering, pageOf, str, type RawParams } from "@/lib/search-params";
import { load, requirePermission } from "@/server/auth";
import source from "@/server/data/source";

import { UsersTable } from "./UsersTable";

export async function generateMetadata(): Promise<Metadata> {
  return { title: (await getTranslations("admin.nav"))("users") };
}

/** Liste des utilisateurs : recherche (email, nom, identifiant) et filtres dans l'URL. */
export default async function UsersPage({ searchParams }: PageProps<"/users">) {
  const { ctx } = await requirePermission("users.view");
  const params = (await searchParams) as RawParams;
  const t = await getTranslations("admin.users");
  const query = {
    ...pageOf(params),
    q: str(params, "q"),
    plan: oneOf(params, "plan", TIERS),
    status: oneOf(params, "status", USER_STATUSES),
    country: str(params, "country", 2)?.toUpperCase(),
    ordering: ordering(params, ["created_at", "last_seen_at", "name", "email"]),
  };
  const data = await load(source.users.list(query, ctx));

  return (
    <div className="page">
      <PageHeader title={t("title")} subtitle={t("subtitle", { count: data.count })} />
      <UsersTable rows={data.results} total={data.count} page={data.page} pageSize={data.page_size} />
    </div>
  );
}
