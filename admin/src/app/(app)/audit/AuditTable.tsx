"use client";

import { useTranslations } from "next-intl";
import { useMemo } from "react";

import { DataTable, type Column } from "@/components/ui/DataTable";
import { Diff } from "@/components/ui/Diff";
import { SearchFilter, SelectFilter } from "@/components/ui/Filters";
import { Tag } from "@/components/ui/Tags";
import type { components } from "@/lib/api/schema";
import { diffObjects } from "@/lib/diff";
import { formatDateTime } from "@/lib/format";

type Entry = components["schemas"]["AuditEntry"];

const DOMAINS = ["users", "content", "feedback", "billing", "support", "campaigns", "settings", "team", "approvals"] as const;
const TARGETS = ["user", "payment", "plan", "quotas", "promo", "ticket", "campaign", "settings", "staff", "approval", "feedback"] as const;

export function AuditTable({ rows, total, page, pageSize }: { rows: Entry[]; total: number; page: number; pageSize: number }) {
  const t = useTranslations("admin.audit");
  const tc = useTranslations("admin.common");
  const columns = useMemo<Column<Entry>[]>(
    () => [
      { id: "created_at", header: t("col_when"), cell: ({ row }) => <span className="num">{formatDateTime(row.original.created_at)}</span> },
      { id: "actor", header: t("col_who"), cell: ({ row }) => row.original.actor ?? t("system") },
      { id: "action", header: t("col_action"), cell: ({ row }) => <Tag>{row.original.action}</Tag> },
      {
        id: "target",
        header: t("col_target"),
        cell: ({ row }) => (
          <span className="small">
            {row.original.target_type} · <code>{row.original.target_id?.slice(0, 24)}</code>
          </span>
        ),
      },
      {
        id: "diff",
        header: t("col_detail"),
        cell: ({ row }) => {
          const lines = diffObjects(row.original.before, row.original.after);
          return lines.length ? (
            <details>
              <summary className="small">{t("changes", { count: lines.length })}</summary>
              <Diff lines={lines} label={t("col_detail")} emptyLabel={t("no_change")} />
            </details>
          ) : (
            <span className="faint small">{t("no_change")}</span>
          );
        },
      },
      { id: "ip", header: t("col_ip"), cell: ({ row }) => <span className="faint small num">{row.original.ip ?? "—"}</span> },
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
      tools={
        <>
          <SearchFilter label={t("search_target")} param="target_id" />
          <SelectFilter label={t("col_action")} param="action" allLabel={tc("all")} options={DOMAINS.map((d) => ({ value: d, label: t(`domain_${d}`) }))} />
          <SelectFilter label={t("col_target")} param="target_type" allLabel={tc("all")} options={TARGETS.map((d) => ({ value: d, label: d }))} />
        </>
      }
    />
  );
}
