"use client";

import { useTranslations } from "next-intl";
import { useState } from "react";

import { Icon } from "@/components/icons/Icon";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { useAction } from "@/hooks/use-action";
import type { components } from "@/lib/api/schema";
import { formatDate, formatNumber } from "@/lib/format";

import { revealHealth } from "../actions";

type Health = components["schemas"]["AdminUserHealth"];

/**
 * Données de santé masquées par défaut. Révélation à l'unité : motif obligatoire, step-up, et
 * consultation journalisée par l'API. Rien n'est conservé : quitter la page les masque à nouveau.
 */
export function HealthReveal({ userId, allowed }: { userId: string; allowed: boolean }) {
  const t = useTranslations("admin.users");
  const { run } = useAction(revealHealth);
  const [health, setHealth] = useState<Health | null>(null);

  return (
    <section className="card stack" aria-labelledby="health-title">
      <div className="ch">
        <h3 id="health-title" className="row">
          <Icon name="lock" />
          {t("health_title")}
        </h3>
        <div className="r">
          {health ? (
            <button type="button" className="btn ghost sm" onClick={() => setHealth(null)}>
              <Icon name="eyeOff" />
              {t("health_hide")}
            </button>
          ) : allowed ? (
            <ConfirmDialog
              trigger={
                <button type="button" className="btn ghost sm">
                  <Icon name="eye" />
                  {t("health_reveal")}
                </button>
              }
              title={t("health_reveal_title")}
              description={t("health_reveal_body")}
              confirmLabel={t("health_reveal")}
              requireReason
              onConfirm={async (reason) => {
                const result = await run({ id: userId, reason }, { handleValidation: true });
                if (result.ok && "data" in result) setHealth(result.data);
                return result.ok;
              }}
            />
          ) : null}
        </div>
      </div>
      {health ? (
        <dl className="kv">
          <dt>{t("health_birth")}</dt>
          <dd>{formatDate(health.birth_date)}</dd>
          <dt>{t("health_sex")}</dt>
          <dd>{health.sex ? t(`sex_${health.sex}`) : "—"}</dd>
          <dt>{t("health_height")}</dt>
          <dd>{health.height_cm ? `${formatNumber(health.height_cm)} cm` : "—"}</dd>
          <dt>{t("health_weight")}</dt>
          <dd>{health.current_weight_kg ? `${formatNumber(health.current_weight_kg, 1)} kg` : "—"}</dd>
          <dt>{t("health_target")}</dt>
          <dd>{health.target_weight_kg ? `${formatNumber(health.target_weight_kg, 1)} kg` : "—"}</dd>
          <dt>{t("health_kcal")}</dt>
          <dd>{health.targets ? `${formatNumber(health.targets.kcal)} kcal` : "—"}</dd>
        </dl>
      ) : (
        <p className="note lock">
          <Icon name="shield" />
          <span>{t(allowed ? "health_masked" : "health_forbidden")}</span>
        </p>
      )}
    </section>
  );
}
