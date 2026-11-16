import "server-only";

import { audit, fourEyesEnabled, problem, requestApproval, run } from "@/server/mock/runtime";
import { store } from "@/server/mock/state";

import type { Settings, SettingsRepository } from ".";

/** Bornes des constantes nutritionnelles, comme les valide l'API (422 hors bornes). */
const BOUNDS: Record<string, [number, number]> = {
  activity_factor: [1, 2],
  lose_weight_deficit: [0.15, 0.2],
  gain_muscle_surplus: [0.1, 0.15],
  water_ml_per_kg: [25, 45],
  water_ml_per_active_hour: [250, 1000],
  salt_max_g: [3, 6],
  activity_bonus_ratio: [0, 1],
  kcal_target_tolerance: [0.05, 0.2],
};

function outOfBounds(nutrition: Settings["nutrition"]): Record<string, { code: string; message: string }[]> {
  const errors: Record<string, { code: string; message: string }[]> = {};
  for (const [key, [min, max]] of Object.entries(BOUNDS)) {
    const value = (nutrition as Record<string, unknown> | undefined)?.[key];
    if (typeof value === "number" && (value < min || value > max)) {
      errors[`nutrition.${key}`] = [{ code: "range", message: `Entre ${min} et ${max}` }];
    }
  }
  return errors;
}

export const settingsMock: SettingsRepository = {
  get: (ctx) => run(ctx, { permission: "settings.view" }, () => store().settings),

  update: (input, ctx) =>
    run(ctx, { permission: "settings.edit", stepUp: true }, ({ staff }) => {
      const { reason, ...changes } = input;
      if (!reason || reason.trim().length < 3) {
        return problem(400, "validation_error", { errors: { reason: [{ code: "required", message: "Motif obligatoire" }] } });
      }
      const errors = outOfBounds(changes.nutrition);
      if (Object.keys(errors).length) return problem(400, "validation_error", { errors });

      const current = store().settings;
      const nutritionChanged =
        changes.nutrition !== undefined && JSON.stringify(changes.nutrition) !== JSON.stringify(current.nutrition);
      const apply = () => {
        const before = structuredClone(current);
        store().settings = { ...current, ...changes };
        audit(staff, "settings.edit", { type: "settings", id: "app" }, before, { ...changes, reason });
      };
      if (nutritionChanged && fourEyesEnabled("settings")) {
        const approval = requestApproval(
          staff,
          {
            kind: "settings_nutrition",
            domain: "settings",
            summary: "Modifier les constantes de calcul nutritionnel",
            target_type: "settings",
            target_id: "nutrition",
            diff: { before: current.nutrition, after: changes.nutrition },
            reason,
          },
          apply,
        );
        return "code" in approval ? approval : { status: "pending" as const, approval };
      }
      apply();
      return { status: "applied" as const, data: store().settings };
    }),
};
