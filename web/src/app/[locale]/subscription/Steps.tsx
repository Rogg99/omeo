import { getTranslations } from "next-intl/server";

import { Icon } from "@/components/icons/Icon";

const STEPS = ["step_login", "step_plan", "step_payment"] as const;

/** Étapes de l'abonnement (connexion, offre, paiement), annoncées aux lecteurs d'écran. */
export async function Steps({ current }: { current: 0 | 1 | 2 }) {
  const t = await getTranslations("web");
  return (
    <ol className="steps" aria-label={t("a11y.steps")}>
      {STEPS.map((key, i) => {
        const label = t(`subscription.${key}`);
        const done = i < current;
        return (
          <li key={key} className={done ? "done" : undefined} aria-current={i === current ? "step" : undefined}>
            {i > 0 ? <span className="sep" aria-hidden="true" /> : null}
            <i aria-hidden="true">{done ? <Icon name="check" size={14} /> : i + 1}</i>
            <span className="sr-only">{done ? t("a11y.step_done", { label }) : i === current ? t("a11y.step_current", { label }) : label}</span>
            <span aria-hidden="true">{label}</span>
          </li>
        );
      })}
    </ol>
  );
}
