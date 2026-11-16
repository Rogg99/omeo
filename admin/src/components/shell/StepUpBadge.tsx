"use client";

import { useTranslations } from "next-intl";
import { useEffect, useState } from "react";

import { Icon } from "@/components/icons/Icon";
import { useStaff } from "@/components/providers/StaffProvider";

/** Temps restant de la double authentification récente (mfa_verified_until de GET /admin/me). */
export function StepUpBadge() {
  const t = useTranslations("admin.shell");
  const { staff } = useStaff();
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 30_000);
    return () => window.clearInterval(timer);
  }, []);

  const until = staff.mfaVerifiedUntil ? Date.parse(staff.mfaVerifiedUntil) : 0;
  const minutes = Math.ceil((until - now) / 60_000);
  const active = minutes > 0;
  return (
    <span className={`tag ${active ? "green" : ""}`} title={active ? t("step_up_active", { minutes }) : t("step_up_inactive")}>
      <Icon name={active ? "shieldCheck" : "shield"} />
      <span>{active ? `${minutes} min` : "2FA"}</span>
      <span className="sr-only">{active ? t("step_up_active", { minutes }) : t("step_up_inactive")}</span>
    </span>
  );
}
