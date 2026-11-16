"use client";

import { useTranslations } from "next-intl";
import type { ReactNode } from "react";

import type { components } from "@/lib/api/schema";

type S = components["schemas"];
type Tone = "" | "green" | "orange" | "red" | "amber" | "blue" | "black";

/** Pastille. La couleur n'est jamais seule : le texte porte toujours l'information. */
export function Tag({ tone = "", children }: { tone?: Tone; children: ReactNode }) {
  return <span className={`tag ${tone}`}>{children}</span>;
}

const TIER_TONE: Record<S["PlanTier"], Tone> = { trial: "orange", free: "", plus: "green" };
export function TierTag({ tier }: { tier: S["PlanTier"] }) {
  const t = useTranslations("admin.users");
  return <Tag tone={TIER_TONE[tier]}>{t(`tier_${tier}`)}</Tag>;
}

const USER_STATUS_TONE: Record<S["AdminUserRow"]["status"], Tone> = { active: "green", suspended: "red", deletion_pending: "amber" };
export function UserStatusTag({ status }: { status: S["AdminUserRow"]["status"] }) {
  const t = useTranslations("admin.users");
  return <Tag tone={USER_STATUS_TONE[status]}>{t(`status_${status}`)}</Tag>;
}

const CONTENT_TONE: Record<S["ContentStatus"], Tone> = { draft: "", review: "orange", published: "green", archived: "red" };
export function ContentStatusTag({ status }: { status: S["ContentStatus"] }) {
  const t = useTranslations("admin.content");
  return <Tag tone={CONTENT_TONE[status]}>{t(`status_${status}`)}</Tag>;
}

const TICKET_TONE: Record<S["TicketStatus"], Tone> = { new: "blue", open: "orange", waiting_user: "", resolved: "green", closed: "" };
export function TicketStatusTag({ status }: { status: S["TicketStatus"] }) {
  const t = useTranslations("admin.support");
  return <Tag tone={TICKET_TONE[status]}>{t(`status_${status}`)}</Tag>;
}

const SUB_TONE: Record<S["SubscriptionStatus"], Tone> = { trial: "orange", active: "green", grace: "amber", canceled: "", expired: "red", refunded: "blue" };
export function SubscriptionStatusTag({ status }: { status: S["SubscriptionStatus"] }) {
  const t = useTranslations("admin.billing");
  return <Tag tone={SUB_TONE[status]}>{t(`sub_status_${status}`)}</Tag>;
}

const PAYMENT_TONE: Record<S["Payment"]["status"], Tone> = { succeeded: "green", failed: "red", refunded: "blue", pending: "amber" };
export function PaymentStatusTag({ status }: { status: S["Payment"]["status"] }) {
  const t = useTranslations("admin.billing");
  return <Tag tone={PAYMENT_TONE[status]}>{t(`pay_status_${status}`)}</Tag>;
}

const APPROVAL_TONE: Record<S["ApprovalRequest"]["status"], Tone> = { pending: "orange", approved: "green", rejected: "red", expired: "", canceled: "" };
export function ApprovalStatusTag({ status }: { status: S["ApprovalRequest"]["status"] }) {
  const t = useTranslations("admin.approvals");
  return <Tag tone={APPROVAL_TONE[status]}>{t(`status_${status}`)}</Tag>;
}
