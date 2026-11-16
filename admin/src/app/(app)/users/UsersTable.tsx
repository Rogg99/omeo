"use client";

import Link from "next/link";
import { useTranslations } from "next-intl";
import { useMemo } from "react";

import { DataTable, type Column } from "@/components/ui/DataTable";
import { SearchFilter, SelectFilter } from "@/components/ui/Filters";
import { TierTag, UserStatusTag } from "@/components/ui/Tags";
import type { components } from "@/lib/api/schema";
import { COUNTRIES, TIERS, USER_STATUSES } from "@/lib/domain";
import { formatDate, formatRelative, initials } from "@/lib/format";

type UserRow = components["schemas"]["AdminUserRow"];

export function UsersTable({ rows, total, page, pageSize }: { rows: UserRow[]; total: number; page: number; pageSize: number }) {
  const t = useTranslations("admin.users");
  const tc = useTranslations("admin.common");

  const columns = useMemo<Column<UserRow>[]>(
    () => [
      {
        id: "name",
        header: t("col_user"),
        accessorKey: "name",
        enableSorting: true,
        cell: ({ row }) => (
          <div className="row">
            <span className="av" aria-hidden="true">
              {initials(row.original.name)}
            </span>
            <div>
              <Link href={`/users/${row.original.id}`} className="row-link">
                {row.original.name}
              </Link>
              <div className="faint small">{row.original.email}</div>
            </div>
          </div>
        ),
      },
      { id: "tier", header: t("col_tier"), cell: ({ row }) => <TierTag tier={row.original.tier} /> },
      { id: "status", header: t("col_status"), cell: ({ row }) => <UserStatusTag status={row.original.status} /> },
      { id: "country", header: t("col_country"), cell: ({ row }) => row.original.country ?? "—" },
      { id: "locale", header: t("col_locale"), cell: ({ row }) => row.original.locale?.toUpperCase() ?? "—" },
      {
        id: "created_at",
        header: t("col_created"),
        enableSorting: true,
        accessorKey: "created_at",
        cell: ({ row }) => formatDate(row.original.created_at),
      },
      {
        id: "last_seen_at",
        header: t("col_last_seen"),
        enableSorting: true,
        accessorKey: "last_seen_at",
        cell: ({ row }) => formatRelative(row.original.last_seen_at),
      },
    ],
    [t],
  );

  return (
    <DataTable
      caption={t("title")}
      columns={columns}
      data={rows}
      total={total}
      page={page}
      pageSize={pageSize}
      rowKey={(r) => r.id}
      empty={t("empty")}
      tools={
        <>
          <SearchFilter label={t("search")} />
          <SelectFilter label={t("col_tier")} param="plan" allLabel={tc("all")} options={TIERS.map((v) => ({ value: v, label: t(`tier_${v}`) }))} />
          <SelectFilter label={t("col_status")} param="status" allLabel={tc("all")} options={USER_STATUSES.map((v) => ({ value: v, label: t(`status_${v}`) }))} />
          <SelectFilter label={t("col_country")} param="country" allLabel={tc("all")} options={COUNTRIES.map((c) => ({ value: c, label: c }))} />
        </>
      }
    />
  );
}
