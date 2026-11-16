"use client";

import * as DropdownMenu from "@radix-ui/react-dropdown-menu";
import { useTranslations } from "next-intl";
import { useState } from "react";

import { Icon, type IconName } from "@/components/icons/Icon";
import { useCan } from "@/components/providers/StaffProvider";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { useAction } from "@/hooks/use-action";
import type { components } from "@/lib/api/schema";
import { USER_ACTION_PERMISSION, type UserAction } from "@/lib/permissions";

import { userAction } from "../actions";

type User = Pick<components["schemas"]["AdminUserRow"], "id" | "name" | "email" | "status" | "tier">;

type Spec = {
  action: UserAction;
  icon: IconName;
  danger?: boolean;
  /** Confirmation forte : recopier l'email. */
  strong?: boolean;
  days?: { max: number; fallback: number };
  feature?: boolean;
  visible?: (u: User) => boolean;
};

const ACTIONS: Spec[] = [
  { action: "grant_plus_days", icon: "gift", days: { max: 365, fallback: 30 } },
  { action: "extend_trial", icon: "clock", days: { max: 14, fallback: 3 }, visible: (u) => u.tier === "trial" },
  { action: "reset_quota", icon: "refresh", feature: true },
  { action: "resend_verification", icon: "mail" },
  { action: "send_password_reset", icon: "key" },
  { action: "export_data", icon: "download" },
  { action: "suspend", icon: "ban", danger: true, strong: true, visible: (u) => u.status !== "suspended" },
  { action: "reactivate", icon: "check", visible: (u) => u.status === "suspended" },
  { action: "delete_data", icon: "trash", danger: true, strong: true, visible: (u) => u.status !== "deletion_pending" },
];

/** Actions sur le compte, filtrées par permission ; motif obligatoire, confirmation forte si destructive. */
export function UserActions({ user }: { user: User }) {
  const t = useTranslations("admin.users");
  const can = useCan();
  const { run } = useAction(userAction);
  const [days, setDays] = useState<Record<string, number>>({});
  const [feature, setFeature] = useState<"photo_analysis" | "text_analysis">("photo_analysis");
  const available = ACTIONS.filter((a) => can(USER_ACTION_PERMISSION[a.action]) && (a.visible?.(user) ?? true));
  if (available.length === 0) return null;

  const dialog = (spec: Spec, trigger: React.ReactNode) => (
    <ConfirmDialog
      key={spec.action}
      trigger={trigger}
      title={t(`action_${spec.action}`)}
      description={t(`action_${spec.action}_body`, { name: user.name })}
      confirmLabel={t(`action_${spec.action}`)}
      danger={spec.danger}
      requireReason
      confirmValue={spec.strong ? user.email : undefined}
      onConfirm={async (reason) => {
        const result = await run(
          {
            id: user.id,
            action: spec.action,
            reason,
            ...(spec.days ? { days: days[spec.action] ?? spec.days.fallback } : {}),
            ...(spec.feature ? { feature } : {}),
          },
          { success: t("action_done") },
        );
        return result.ok;
      }}
    >
      {spec.days ? (
        <div className="f">
          <label htmlFor={`days-${spec.action}`}>{t("days_label", { max: spec.days.max })}</label>
          <input
            id={`days-${spec.action}`}
            type="number"
            min={1}
            max={spec.days.max}
            value={days[spec.action] ?? spec.days.fallback}
            onChange={(e) => setDays((d) => ({ ...d, [spec.action]: Math.min(spec.days?.max ?? 1, Math.max(1, Number(e.target.value))) }))}
          />
        </div>
      ) : null}
      {spec.feature ? (
        <div className="f">
          <label htmlFor="quota-feature">{t("quota_feature")}</label>
          <select id="quota-feature" value={feature} onChange={(e) => setFeature(e.target.value as typeof feature)}>
            <option value="photo_analysis">{t("quota_photo_analysis")}</option>
            <option value="text_analysis">{t("quota_text_analysis")}</option>
          </select>
        </div>
      ) : null}
    </ConfirmDialog>
  );

  const primary = available.filter((a) => a.danger);
  const secondary = available.filter((a) => !a.danger);

  return (
    <>
      {secondary.length ? (
        <DropdownMenu.Root modal={false}>
          <DropdownMenu.Trigger asChild>
            <button type="button" className="btn ghost">
              {t("actions")}
              <Icon name="chevD" />
            </button>
          </DropdownMenu.Trigger>
          <DropdownMenu.Portal>
            <DropdownMenu.Content className="popover" align="end" sideOffset={6}>
              {secondary.map((spec) =>
                dialog(
                  spec,
                  <DropdownMenu.Item onSelect={(e) => e.preventDefault()}>
                    <Icon name={spec.icon} />
                    {t(`action_${spec.action}`)}
                  </DropdownMenu.Item>,
                ),
              )}
            </DropdownMenu.Content>
          </DropdownMenu.Portal>
        </DropdownMenu.Root>
      ) : null}
      {primary.map((spec) =>
        dialog(
          spec,
          <button type="button" className="btn danger">
            <Icon name={spec.icon} />
            {t(`action_${spec.action}`)}
          </button>,
        ),
      )}
    </>
  );
}
