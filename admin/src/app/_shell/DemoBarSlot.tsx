import "server-only";

import { cookies } from "next/headers";
import { getTranslations } from "next-intl/server";

import { MOCK_SCENARIO_COOKIE, isMockScenario } from "@/lib/mock-scenarios";
import source from "@/server/data/source";

import { DemoBar } from "@/components/shell/DemoBar";

/** Bandeau « Données simulées » : rendu seulement en mode mock. */
export async function DemoBarSlot({ currentEmail }: { currentEmail?: string }) {
  if (!source.demo) return null;
  const [store, t] = await Promise.all([cookies(), getTranslations("admin.role")]);
  const value = store.get(MOCK_SCENARIO_COOKIE)?.value;
  const accounts = source.demoAccounts.map((a) => ({
    email: a.email,
    label: `${a.name} · ${a.roles.map((r) => t(r)).join(", ")}`,
  }));
  return <DemoBar accounts={accounts} current={currentEmail} scenario={isMockScenario(value) ? value : "normal"} />;
}
