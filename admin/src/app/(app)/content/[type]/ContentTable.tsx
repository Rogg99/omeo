"use client";

import Image from "next/image";
import Link from "next/link";
import { useTranslations } from "next-intl";
import { useMemo } from "react";

import { DataTable, type Column } from "@/components/ui/DataTable";
import { SearchFilter, SelectFilter } from "@/components/ui/Filters";
import { ContentStatusTag, Tag } from "@/components/ui/Tags";
import type { components } from "@/lib/api/schema";
import { CONTENT_STATUSES, type ContentType } from "@/lib/content-types";
import { formatRelative } from "@/lib/format";
import { LOCALES } from "@/lib/locales";

type Row = components["schemas"]["AdminContentRow"];

export function ContentTable({ type, rows, total, page, pageSize }: { type: ContentType; rows: Row[]; total: number; page: number; pageSize: number }) {
  const t = useTranslations("admin.content");
  const tc = useTranslations("admin.common");
  const columns = useMemo<Column<Row>[]>(
    () => [
      {
        id: "title",
        header: t("col_title"),
        accessorKey: "title",
        enableSorting: true,
        cell: ({ row }) => (
          <div className="row">
            {row.original.thumbnail ? <Image src={row.original.thumbnail.url} alt="" width={48} height={48} className="thumb" unoptimized /> : null}
            <Link href={`/content/${type}/${row.original.id}`} className="row-link">
              {row.original.title}
            </Link>
          </div>
        ),
      },
      { id: "status", header: t("col_status"), cell: ({ row }) => <ContentStatusTag status={row.original.status} /> },
      {
        id: "translations",
        header: t("col_translations"),
        cell: ({ row }) =>
          row.original.missing_locales.length === 0 ? (
            <Tag tone="green">{t("translations_complete")}</Tag>
          ) : (
            <Tag tone="orange">{t("translations_missing", { count: row.original.missing_locales.length, list: row.original.missing_locales.join(", ").toUpperCase() })}</Tag>
          ),
      },
      {
        id: "updated_at",
        header: t("col_updated"),
        accessorKey: "updated_at",
        enableSorting: true,
        cell: ({ row }) => (
          <span className="small">
            {formatRelative(row.original.updated_at)}
            {row.original.updated_by ? ` · ${row.original.updated_by}` : ""}
          </span>
        ),
      },
    ],
    [t, type],
  );
  return (
    <DataTable
      caption={t(`type_${type}`)}
      columns={columns}
      data={rows}
      total={total}
      page={page}
      pageSize={pageSize}
      rowKey={(r) => r.id}
      empty={t("empty")}
      tools={
        <>
          <SearchFilter label={tc("search")} />
          <SelectFilter label={t("col_status")} param="status" allLabel={tc("all")} options={CONTENT_STATUSES.map((s) => ({ value: s, label: t(`status_${s}`) }))} />
          <SelectFilter label={t("missing_locale")} param="missing_locale" allLabel={tc("all")} options={LOCALES.map((l) => ({ value: l, label: l.toUpperCase() }))} />
        </>
      }
    />
  );
}
