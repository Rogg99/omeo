"use client";

import { useActionState, useId, useState } from "react";

import { FormAlert } from "@/components/forms/FormAlert";
import { IDLE, type FormState } from "@/lib/form-state";

import { openPortal } from "../actions";

export function PortalButton({ label, pending: pendingLabel }: { label: string; pending: string }) {
  const [state, action, pending] = useActionState<FormState, FormData>(openPortal, IDLE);
  const errorId = useId();
  return (
    <form action={action} className="stack mt16">
      <FormAlert state={state} id={errorId} />
      <button type="submit" className="btn" disabled={pending}>
        {pending ? pendingLabel : label}
      </button>
    </form>
  );
}

export type PaymentRow = { id: string; description: string; date: string; amount: string; status: string; receiptUrl: string | null };

type ApiPayment = {
  id: string;
  description?: string;
  paid_at: string;
  amount: { formatted?: string };
  status: string;
  receipt_url?: string | null;
};

type PaymentsListProps = {
  initial: PaymentRow[];
  cursor: string | null;
  locale: string;
  labels: { loadMore: string; receipt: string; external: string; statuses: Record<string, string>; error: string };
};

/** Historique des paiements ; les pages suivantes sont chargées via /api/me/payments. */
export function PaymentsList({ initial, cursor: initialCursor, locale, labels }: PaymentsListProps) {
  const [rows, setRows] = useState(initial);
  const [cursor, setCursor] = useState(initialCursor);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(false);
  const date = new Intl.DateTimeFormat(locale, { dateStyle: "medium" });

  const more = async () => {
    if (!cursor) return;
    setLoading(true);
    setError(false);
    try {
      const response = await fetch(`/api/me/payments?cursor=${encodeURIComponent(cursor)}`, { cache: "no-store" });
      if (response.status === 401) return window.location.reload();
      if (!response.ok) throw new Error(String(response.status));
      const page = (await response.json()) as { results?: ApiPayment[]; next_cursor: string | null };
      setRows((current) => [
        ...current,
        ...(page.results ?? []).map((p) => ({
          id: p.id,
          description: p.description ?? "",
          date: date.format(new Date(p.paid_at)),
          amount: p.amount.formatted ?? "",
          status: p.status,
          receiptUrl: p.receipt_url ?? null,
        })),
      ]);
      setCursor(page.next_cursor);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <ul className="list mt16">
        {rows.map((row) => (
          <li key={row.id}>
            <span>
              <b>{row.description}</b>
              <span className="small muted" style={{ display: "block" }}>
                {row.date} · {labels.statuses[row.status] ?? row.status}
              </span>
            </span>
            <span className="row">
              <b>{row.amount}</b>
              {row.receiptUrl ? (
                <a className="small" href={row.receiptUrl} target="_blank" rel="noopener noreferrer">
                  {labels.receipt}
                  <span className="sr-only"> {labels.external}</span>
                </a>
              ) : null}
            </span>
          </li>
        ))}
      </ul>
      {error ? (
        <p className="field-error mt8" role="alert">
          {labels.error}
        </p>
      ) : null}
      {cursor ? (
        <button type="button" className="btn ghost sm mt16" onClick={more} disabled={loading}>
          {labels.loadMore}
        </button>
      ) : null}
    </>
  );
}
