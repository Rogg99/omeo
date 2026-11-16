"use client";

import { useTranslations } from "next-intl";
import { usePathname, useRouter } from "next/navigation";

import { setDemoScenario, switchDemoAccount } from "@/app/actions/auth";
import { useCsrf } from "@/components/providers/StaffProvider";
import { MOCK_SCENARIOS, type MockScenario } from "@/lib/mock-scenarios";

export type DemoAccount = { email: string; label: string };

/**
 * Bandeau du mode mock : « Données simulées », compte de démo (un par rôle) et scénario.
 * Rendu uniquement quand la couche de données est simulée ; absent du build de production.
 */
export function DemoBar({
  accounts,
  current,
  scenario,
}: {
  accounts: DemoAccount[];
  current?: string;
  scenario: MockScenario;
}) {
  const t = useTranslations("admin.mock");
  const csrf = useCsrf();
  const router = useRouter();
  const pathname = usePathname();

  return (
    <div className="demo-bar" role="region" aria-label={t("banner")}>
      <strong>{t("banner")}</strong>
      <label className="row">
        <span>{t("role")}</span>
        <select
          value={current ?? ""}
          onChange={(e) => void switchDemoAccount({ email: e.target.value, next: pathname, csrf })}
        >
          {current ? null : <option value="">—</option>}
          {accounts.map((a) => (
            <option key={a.email} value={a.email}>
              {a.label}
            </option>
          ))}
        </select>
      </label>
      <label className="row">
        <span>{t("scenario")}</span>
        <select
          value={scenario}
          onChange={async (e) => {
            await setDemoScenario({ scenario: e.target.value, csrf });
            router.refresh();
          }}
        >
          {MOCK_SCENARIOS.map((s) => (
            <option key={s} value={s}>
              {t(`scenario_${s}`)}
            </option>
          ))}
        </select>
      </label>
      <span>{t("hint")}</span>
    </div>
  );
}
