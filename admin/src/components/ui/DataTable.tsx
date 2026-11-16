"use client";

import { rowSortingFeature, tableFeatures, useTable, type ColumnDef, type RowData, type SortingState } from "@tanstack/react-table";
import { useTranslations } from "next-intl";
import { useMemo, type ReactNode } from "react";

import { Icon } from "@/components/icons/Icon";

import { useUrlParams } from "./Filters";

const features = tableFeatures({ rowSortingFeature });

export type Column<T extends RowData> = ColumnDef<typeof features, T>;

/**
 * Table TanStack Table (v9) : tri et pagination côté serveur, état dans l'URL (`ordering`, `page`).
 * Les données affichées sont celles renvoyées par l'API pour la page courante.
 */
export function DataTable<T extends RowData>({
  columns,
  data,
  total,
  page,
  pageSize,
  tools,
  caption,
  empty,
  rowKey,
}: {
  columns: Column<T>[];
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  tools?: ReactNode;
  caption: string;
  empty?: ReactNode;
  rowKey: (row: T) => string;
}) {
  const t = useTranslations("admin.common");
  const { params, set, pending } = useUrlParams();
  const ordering = params.get("ordering") ?? "";
  const sorting = useMemo<SortingState>(
    () => (ordering ? [{ id: ordering.replace(/^-/, ""), desc: ordering.startsWith("-") }] : []),
    [ordering],
  );

  const table = useTable({
    features,
    columns,
    data,
    getRowId: rowKey,
    manualSorting: true,
    enableSortingRemoval: true,
    state: { sorting },
    onSortingChange: (updater) => {
      const next = typeof updater === "function" ? updater(sorting) : updater;
      const first = next[0];
      set({ ordering: first ? `${first.desc ? "-" : ""}${first.id}` : null });
    },
  });

  const from = total === 0 ? 0 : (page - 1) * pageSize + 1;
  const to = Math.min(total, page * pageSize);
  const lastPage = Math.max(1, Math.ceil(total / pageSize));

  return (
    <div className="tbl-wrap" aria-busy={pending}>
      {tools ? <div className="tbl-tools">{tools}</div> : null}
      <div className="tbl-scroll">
        <table>
          <caption className="sr-only">{caption}</caption>
          <thead>
            {table.getHeaderGroups().map((group) => (
              <tr key={group.id}>
                {group.headers.map((header) => {
                  const sortable = header.column.getCanSort();
                  const sorted = header.column.getIsSorted();
                  const meta = header.column.columnDef.meta as { numeric?: boolean } | undefined;
                  return (
                    <th
                      key={header.id}
                      className={meta?.numeric ? "num" : undefined}
                      aria-sort={sorted === "asc" ? "ascending" : sorted === "desc" ? "descending" : undefined}
                    >
                      {sortable ? (
                        <button type="button" onClick={header.column.getToggleSortingHandler()}>
                          <table.FlexRender header={header} />
                          {sorted ? <Icon name={sorted === "asc" ? "chevU" : "chevD"} size={14} /> : null}
                        </button>
                      ) : (
                        <table.FlexRender header={header} />
                      )}
                    </th>
                  );
                })}
              </tr>
            ))}
          </thead>
          <tbody>
            {table.getRowModel().rows.length === 0 ? (
              <tr>
                <td colSpan={columns.length}>
                  <div className="empty">{empty ?? t("empty")}</div>
                </td>
              </tr>
            ) : (
              table.getRowModel().rows.map((row) => (
                <tr key={row.id}>
                  {row.getAllCells().map((cell) => {
                    const meta = cell.column.columnDef.meta as { numeric?: boolean } | undefined;
                    return (
                      <td key={cell.id} className={meta?.numeric ? "num" : undefined}>
                        <table.FlexRender cell={cell} />
                      </td>
                    );
                  })}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
      <div className="pager">
        <span>{t("page_range", { from, to, total })}</span>
        <span className="grow" />
        <button
          type="button"
          className="icon-b"
          aria-label={t("previous")}
          disabled={page <= 1}
          onClick={() => set({ page: page - 1 > 1 ? String(page - 1) : null }, false)}
        >
          <Icon name="chevL" />
        </button>
        <button
          type="button"
          className="icon-b"
          aria-label={t("next")}
          disabled={page >= lastPage}
          onClick={() => set({ page: String(page + 1) }, false)}
        >
          <Icon name="chevR" />
        </button>
      </div>
    </div>
  );
}
