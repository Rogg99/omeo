import type { Metadata } from "next";
import Link from "next/link";
import { getTranslations } from "next-intl/server";

import { Diff } from "@/components/ui/Diff";
import { PageHeader } from "@/components/ui/PageHeader";
import { diffOfApproval } from "@/lib/diff";
import { formatDateTime } from "@/lib/format";
import { oneOf, pageOf, type RawParams } from "@/lib/search-params";
import { load, requirePermission } from "@/server/auth";
import source from "@/server/data/source";

import { ApprovalDecision, ApprovalStatus } from "./ApprovalDecision";

export async function generateMetadata(): Promise<Metadata> {
  return { title: (await getTranslations("admin.nav"))("approvals") };
}

const VIEWS = ["todo", "mine", "history"] as const;

/**
 * Validations à quatre yeux : demandes à traiter (domaine de la personne, jamais les siennes),
 * demandes émises (annulables tant qu'elles attendent) et historique.
 */
export default async function ApprovalsPage({ searchParams }: PageProps<"/approvals">) {
  const { ctx, me } = await requirePermission("approvals.decide");
  const params = (await searchParams) as RawParams;
  const view = oneOf(params, "view", VIEWS) ?? "todo";
  const t = await getTranslations("admin.approvals");
  const query =
    view === "mine"
      ? { ...pageOf(params), mine: true }
      : view === "history"
        ? { ...pageOf(params), status: oneOf(params, "status", ["approved", "rejected", "expired", "canceled"] as const) ?? "approved" }
        : { ...pageOf(params), status: "pending" as const };
  const data = await load(source.approvals.list(query, ctx));

  return (
    <div className="page">
      <PageHeader title={t("title")} subtitle={t("subtitle")} />
      <nav className="tabs" aria-label={t("title")}>
        {VIEWS.map((v) => (
          <Link key={v} href={v === "todo" ? "/approvals" : `/approvals?view=${v}`} aria-current={view === v ? "page" : undefined}>
            {t(`view_${v}`)}
            {v === "todo" && (me.pending_approvals ?? 0) > 0 ? <span className="tag orange">{me.pending_approvals}</span> : null}
          </Link>
        ))}
      </nav>
      {data.results.length === 0 ? (
        <div className="card empty">{t(`empty_${view}`)}</div>
      ) : (
        <div className="stack">
          {data.results.map((a) => (
            <article key={a.id} className="card stack" aria-labelledby={`approval-${a.id}`}>
              <div className="ch">
                <div>
                  <h3 id={`approval-${a.id}`}>{a.summary}</h3>
                  <p className="faint small">
                    {t("meta", { kind: t(`kind_${a.kind}`), by: a.requested_by, date: formatDateTime(a.created_at), expires: formatDateTime(a.expires_at) })}
                  </p>
                </div>
                <div className="r">
                  <ApprovalStatus status={a.status} />
                </div>
              </div>
              {a.reason ? <p className="note lock">{t("reason", { reason: a.reason })}</p> : null}
              <Diff lines={diffOfApproval(a.diff)} label={t("diff")} emptyLabel={t("diff_empty")} />
              {a.decided_by ? (
                <p className="small muted">
                  {t("decided", { by: a.decided_by, date: formatDateTime(a.decided_at) })}
                  {a.decision_comment ? ` — ${a.decision_comment}` : ""}
                </p>
              ) : null}
              {a.status === "pending" ? <ApprovalDecision id={a.id} mine={view === "mine"} /> : null}
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
