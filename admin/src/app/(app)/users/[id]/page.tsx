import type { Metadata } from "next";
import Link from "next/link";
import { getTranslations } from "next-intl/server";

import { Bar } from "@/components/ui/Kpi";
import { PageHeader } from "@/components/ui/PageHeader";
import { PaymentStatusTag, Tag, TicketStatusTag, TierTag, UserStatusTag } from "@/components/ui/Tags";
import { formatDate, formatDateTime, formatNumber, formatRelative, initials } from "@/lib/format";
import { oneOf, type RawParams } from "@/lib/search-params";
import { load, requirePermission } from "@/server/auth";
import source from "@/server/data/source";

import { HealthReveal } from "./HealthReveal";
import { UserActions } from "./UserActions";

export async function generateMetadata({ params }: PageProps<"/users/[id]">): Promise<Metadata> {
  const { id } = await params;
  return { title: `${(await getTranslations("admin.nav"))("users")} · ${id.slice(0, 8)}` };
}

const TABS = ["overview", "billing", "referral", "devices", "consents", "tickets"] as const;

/** Fiche utilisateur : données de santé masquées, révélées à l'unité avec un motif. */
export default async function UserPage({ params, searchParams }: PageProps<"/users/[id]">) {
  const { ctx, can } = await requirePermission("users.view");
  const [{ id }, query] = await Promise.all([params, searchParams]);
  const tab = oneOf(query as RawParams, "tab", TABS) ?? "overview";
  const [user, t, tn] = await Promise.all([load(source.users.get(id, ctx)), getTranslations("admin.users"), getTranslations("admin.nav")]);
  const sub = user.subscription;

  return (
    <div className="page">
      <PageHeader
        crumbs={[{ href: "/users", label: tn("users") }]}
        title={
          <span className="row">
            <span className="av lg" aria-hidden="true">
              {initials(user.name)}
            </span>
            {user.name}
          </span>
        }
        subtitle={t("detail_subtitle", { email: user.email, id: user.id.slice(0, 8), date: formatDate(user.created_at) })}
        actions={<UserActions user={{ id: user.id, name: user.name, email: user.email, status: user.status, tier: user.tier }} />}
      />

      <nav className="tabs" aria-label={t("tabs")}>
        {TABS.map((key) => (
          <Link key={key} href={key === "overview" ? `/users/${id}` : `/users/${id}?tab=${key}`} aria-current={tab === key ? "page" : undefined}>
            {t(`tab_${key}`)}
            {key === "tickets" && user.tickets?.length ? <span className="tag">{user.tickets.length}</span> : null}
          </Link>
        ))}
      </nav>

      {tab === "overview" ? (
        <div className="grid g-21">
          <div className="stack">
            <section className="card">
              <div className="ch">
                <h3>{t("profile")}</h3>
                <div className="r">
                  <UserStatusTag status={user.status} />
                  {user.email_verified ? <Tag tone="green">{t("email_verified")}</Tag> : <Tag tone="amber">{t("email_unverified")}</Tag>}
                </div>
              </div>
              <dl className="kv">
                <dt>{t("col_country")}</dt>
                <dd>{user.country ?? "—"}</dd>
                <dt>{t("col_locale")}</dt>
                <dd>{user.locale?.toUpperCase() ?? "—"}</dd>
                <dt>{t("platform")}</dt>
                <dd>{user.platform ?? "—"}</dd>
                <dt>{t("col_last_seen")}</dt>
                <dd>{formatRelative(user.last_seen_at)}</dd>
                <dt>{t("goals")}</dt>
                <dd>{user.goals?.map((g) => t(`goal_${g}`)).join(", ") || "—"}</dd>
              </dl>
            </section>
            <HealthReveal userId={user.id} allowed={can("users.view_health")} />
            <section className="card">
              <div className="ch">
                <h3>{t("stats")}</h3>
              </div>
              <div className="grid g4">
                {(["meals", "analyses", "streak", "points"] as const).map((k) => (
                  <div key={k} className="kpi">
                    <div className="l">{t(`stat_${k}`)}</div>
                    <div className="v num" style={{ fontSize: 22 }}>
                      {formatNumber(user.stats?.[k])}
                    </div>
                  </div>
                ))}
              </div>
            </section>
          </div>
          <section className="card stack">
            <div className="ch">
              <h3>{t("offer")}</h3>
              <div className="r">
                <TierTag tier={user.tier} />
              </div>
            </div>
            {sub?.trial_days_left ? <p>{t("trial_days_left", { count: sub.trial_days_left })}</p> : null}
            {sub?.granted_days_left ? <p>{t("granted_days_left", { count: sub.granted_days_left })}</p> : null}
            {sub?.quotas?.map((q) => (
              <div key={q.feature} className="stack" style={{ gap: 6 }}>
                <div className="row" style={{ justifyContent: "space-between" }}>
                  <span>{t(`quota_${q.feature}`)}</span>
                  <b className="num small">{q.limit === null ? t("unlimited") : t("quota_used", { used: q.used, limit: q.limit })}</b>
                </div>
                {q.limit ? <Bar ratio={q.used / q.limit} label={t("quota_used", { used: q.used, limit: q.limit })} /> : null}
              </div>
            ))}
            {sub?.subscription ? (
              <dl className="kv">
                <dt>{t("plan")}</dt>
                <dd>{sub.subscription.plan_name ?? sub.subscription.plan_code}</dd>
                <dt>{t("renewal")}</dt>
                <dd>{formatDate(sub.subscription.current_period_end)}</dd>
              </dl>
            ) : null}
          </section>
        </div>
      ) : null}

      {tab === "billing" ? (
        <section className="tbl-wrap">
          <table>
            <caption className="sr-only">{t("tab_billing")}</caption>
            <thead>
              <tr>
                <th>{t("payment_date")}</th>
                <th>{t("payment_desc")}</th>
                <th>{t("payment_channel")}</th>
                <th>{t("col_status")}</th>
                <th className="num">{t("payment_amount")}</th>
              </tr>
            </thead>
            <tbody>
              {user.payments?.length ? (
                user.payments.map((p) => (
                  <tr key={p.id}>
                    <td>{formatDateTime(p.paid_at)}</td>
                    <td>{p.description ?? "—"}</td>
                    <td>{p.channel}</td>
                    <td>
                      <PaymentStatusTag status={p.status} />
                    </td>
                    <td className="num">{p.amount.formatted}</td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5}>
                    <div className="empty">{t("no_payments")}</div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </section>
      ) : null}

      {tab === "referral" && user.referral ? (
        <section className="card stack">
          <dl className="kv">
            <dt>{t("referral_code")}</dt>
            <dd>
              <code>{user.referral.code}</code>
            </dd>
            <dt>{t("referral_validated")}</dt>
            <dd>{formatNumber(user.referral.validated_count)}</dd>
            <dt>{t("referral_days")}</dt>
            <dd>{t("referral_days_value", { earned: user.referral.days_earned, cap: user.referral.days_cap })}</dd>
          </dl>
          {user.referral.referees?.map((r, i) => (
            <div key={`${r.first_name}-${i}`} className="list-i">
              <span style={{ flex: 1 }}>{r.first_name}</span>
              <Tag tone={r.status === "validated" ? "green" : r.status === "rejected" ? "red" : "amber"}>{t(`referee_${r.status ?? "pending"}`)}</Tag>
              <span className="faint small">{formatDate(r.date)}</span>
            </div>
          ))}
        </section>
      ) : null}

      {tab === "devices" ? (
        <section className="card">
          {user.sessions?.length ? (
            user.sessions.map((s) => (
              <div key={s.id} className="list-i">
                <span style={{ flex: 1 }}>
                  <b>{s.device_name}</b> · {s.platform} {s.app_version ? `· ${s.app_version}` : ""}
                </span>
                <span className="faint small">{s.city ?? "—"}</span>
                <span className="small">{formatRelative(s.last_used_at)}</span>
              </div>
            ))
          ) : (
            <div className="empty">{t("no_devices")}</div>
          )}
        </section>
      ) : null}

      {tab === "consents" ? (
        <section className="card">
          {user.consents?.map((c) => (
            <div key={c.kind} className="list-i">
              <span style={{ flex: 1 }}>{t(`consent_${c.kind}`)}</span>
              <Tag tone={c.granted ? "green" : ""}>{c.granted ? t("consent_granted") : t("consent_refused")}</Tag>
              <span className="faint small">{formatDate(c.updated_at)}</span>
            </div>
          ))}
        </section>
      ) : null}

      {tab === "tickets" ? (
        <section className="card">
          {user.tickets?.length ? (
            user.tickets.map((tk) => (
              <div key={tk.id} className="list-i">
                <span style={{ flex: 1 }}>
                  {can("support.view") ? <Link href={`/support/${tk.id}`} className="row-link">{`#${tk.number} · ${tk.subject}`}</Link> : `#${tk.number} · ${tk.subject}`}
                </span>
                <TicketStatusTag status={tk.status} />
                <span className="faint small">{formatRelative(tk.updated_at)}</span>
              </div>
            ))
          ) : (
            <div className="empty">{t("no_tickets")}</div>
          )}
        </section>
      ) : null}
    </div>
  );
}
