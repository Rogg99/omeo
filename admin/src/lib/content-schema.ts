import type { components } from "./api/schema";
import type { ContentType } from "./content-types";

/**
 * Description des champs éditables de chaque type de contenu, alignée sur les schémas Admin* du
 * contrat (AdminFood, AdminRecipe…). L'éditeur générique s'en sert pour son rendu et sa validation ;
 * les types complexes ont des éditeurs dédiés (ingrédients, jours de programme, règles).
 * Les bornes reprennent celles du contrat ; l'API revalide toujours.
 */
export type FieldKind =
  | { kind: "i18n"; long?: boolean }
  | { kind: "text"; pattern?: string }
  | { kind: "number"; min?: number; max?: number; step?: number; unit?: string }
  | { kind: "boolean" }
  | { kind: "select"; options: readonly string[] }
  | { kind: "multi"; options: readonly string[] }
  | { kind: "tags" }
  | { kind: "ref"; type: ContentType; multiple?: boolean }
  | { kind: "media"; media: "image" | "video" }
  | { kind: "subtitles" }
  | { kind: "rule" }
  | { kind: "trigger" }
  | { kind: "ingredients"; key: "food_id" }
  | { kind: "components" }
  | { kind: "steps" }
  | { kind: "workout_steps" }
  | { kind: "program_days" }
  | { kind: "json" };

export type FieldSpec = { name: string; required?: boolean } & FieldKind;

const GOALS = ["lose_weight", "gain_muscle", "eat_balanced", "prevent_diabetes", "prevent_hypertension"] as const;
const LEVELS = ["beginner", "intermediate", "advanced"] as const;

export const CONTENT_FIELDS: Record<ContentType, readonly FieldSpec[]> = {
  foods: [
    { name: "name", kind: "i18n", required: true },
    { name: "aliases", kind: "tags" },
    { name: "category", kind: "text", required: true },
    { name: "kcal", kind: "number", min: 0, max: 900, unit: "kcal", required: true },
    { name: "protein_g", kind: "number", min: 0, max: 100, step: 0.1, unit: "g", required: true },
    { name: "carbs_g", kind: "number", min: 0, max: 100, step: 0.1, unit: "g", required: true },
    { name: "sugars_g", kind: "number", min: 0, max: 100, step: 0.1, unit: "g" },
    { name: "fat_g", kind: "number", min: 0, max: 100, step: 0.1, unit: "g", required: true },
    { name: "saturated_fat_g", kind: "number", min: 0, max: 100, step: 0.01, unit: "g" },
    { name: "fiber_g", kind: "number", min: 0, max: 100, step: 0.1, unit: "g" },
    { name: "salt_g", kind: "number", min: 0, max: 100, step: 0.01, unit: "g" },
    { name: "default_portion_g", kind: "number", min: 0, unit: "g" },
    { name: "source", kind: "text" },
  ],
  dishes: [
    { name: "name", kind: "i18n", required: true },
    { name: "aliases", kind: "tags" },
    { name: "country", kind: "text", pattern: "^[A-Z]{2}$", required: true },
    { name: "standard_portion_g", kind: "number", min: 1, unit: "g", required: true },
    { name: "image_upload_id", kind: "media", media: "image" },
    { name: "recipe_id", kind: "ref", type: "recipes" },
    { name: "components", kind: "components", required: true },
  ],
  recipes: [
    { name: "name", kind: "i18n", required: true },
    { name: "description", kind: "i18n", long: true },
    { name: "country", kind: "text", pattern: "^[A-Z]{2}$" },
    { name: "prep_minutes", kind: "number", min: 0, unit: "min" },
    { name: "cook_minutes", kind: "number", min: 0, unit: "min" },
    { name: "difficulty", kind: "select", options: ["easy", "medium", "hard"] },
    { name: "servings", kind: "number", min: 1, required: true },
    { name: "tags", kind: "tags" },
    { name: "goals", kind: "multi", options: GOALS },
    { name: "is_free", kind: "boolean" },
    { name: "image_upload_id", kind: "media", media: "image" },
    { name: "ingredients", kind: "ingredients", key: "food_id", required: true },
    { name: "steps", kind: "steps", required: true },
  ],
  plants: [
    { name: "common_name", kind: "i18n", required: true },
    { name: "scientific_name", kind: "text", required: true },
    { name: "tags", kind: "tags" },
    { name: "traditional_use", kind: "i18n", long: true, required: true },
    { name: "nutritional_benefits", kind: "i18n", long: true, required: true },
    { name: "precautions", kind: "i18n", long: true, required: true },
    { name: "contraindications", kind: "tags" },
    { name: "related_recipe_ids", kind: "ref", type: "recipes", multiple: true },
    { name: "image_upload_id", kind: "media", media: "image" },
  ],
  exercises: [
    { name: "name", kind: "i18n", required: true },
    { name: "instructions", kind: "i18n", long: true, required: true },
    { name: "muscles", kind: "tags" },
    { name: "level", kind: "select", options: LEVELS, required: true },
    { name: "equipment", kind: "tags" },
    { name: "met", kind: "number", min: 1, max: 20, step: 0.1, required: true },
    { name: "is_free", kind: "boolean" },
    { name: "video_upload_id", kind: "media", media: "video" },
    { name: "subtitle_upload_ids", kind: "subtitles" },
  ],
  workouts: [
    { name: "name", kind: "i18n", required: true },
    { name: "description", kind: "i18n", long: true },
    { name: "goal", kind: "select", options: ["cardio", "strength", "mobility"], required: true },
    { name: "level", kind: "select", options: LEVELS, required: true },
    { name: "is_free", kind: "boolean" },
    { name: "cover_upload_id", kind: "media", media: "image" },
    { name: "steps", kind: "workout_steps", required: true },
  ],
  programs: [
    { name: "name", kind: "i18n", required: true },
    { name: "description", kind: "i18n", long: true },
    { name: "goal", kind: "select", options: GOALS, required: true },
    { name: "weeks", kind: "number", min: 1, max: 52, required: true },
    { name: "points", kind: "number", min: 0 },
    { name: "badge_id", kind: "ref", type: "badges" },
    { name: "cover_upload_id", kind: "media", media: "image" },
    { name: "days", kind: "program_days", required: true },
  ],
  challenges: [
    { name: "name", kind: "i18n", required: true },
    { name: "description", kind: "i18n", long: true },
    { name: "duration_days", kind: "number", min: 7, max: 30, unit: "j", required: true },
    { name: "rule", kind: "rule", required: true },
    { name: "success_threshold", kind: "number", min: 0.5, max: 1, step: 0.05 },
    { name: "points_per_day", kind: "number", min: 0 },
    { name: "points_completion", kind: "number", min: 0 },
    { name: "badge_id", kind: "ref", type: "badges" },
    { name: "cover_upload_id", kind: "media", media: "image" },
  ],
  badges: [
    { name: "code", kind: "text", pattern: "^[a-z0-9_]+$", required: true },
    { name: "family", kind: "select", options: ["streak", "nutrition", "hydration", "activity", "challenge", "program", "discovery", "referral"], required: true },
    { name: "name", kind: "i18n", required: true },
    { name: "description", kind: "i18n", long: true },
    { name: "condition", kind: "json", required: true },
    { name: "bonus_points", kind: "number", min: 0 },
    { name: "icon_upload_id", kind: "media", media: "image" },
  ],
  levels: [
    { name: "rank", kind: "number", min: 1, required: true },
    { name: "name", kind: "i18n", required: true },
    { name: "min_points", kind: "number", min: 0, required: true },
    { name: "icon_upload_id", kind: "media", media: "image" },
  ],
  "point-rules": [
    { name: "action", kind: "text", required: true },
    { name: "points", kind: "number", min: 0, required: true },
    { name: "cap", kind: "number", min: 0 },
    { name: "cap_period", kind: "select", options: ["day", "week", "none"] },
  ],
  "prevention-tips": [
    { name: "code", kind: "text", required: true },
    { name: "topic", kind: "select", options: ["water", "salt", "sugar", "fiber", "activity", "protein"], required: true },
    { name: "title", kind: "i18n", required: true },
    { name: "body", kind: "i18n", long: true, required: true },
    { name: "trigger", kind: "trigger", required: true },
    { name: "tier", kind: "select", options: ["free", "plus"], required: true },
    { name: "related_recipe_ids", kind: "ref", type: "recipes", multiple: true },
    { name: "related_plant_ids", kind: "ref", type: "plants", multiple: true },
  ],
  faq: [
    { name: "category", kind: "text", required: true },
    { name: "question", kind: "i18n", required: true },
    { name: "answer", kind: "i18n", long: true, required: true },
    { name: "order", kind: "number", min: 0 },
    { name: "audience", kind: "select", options: ["app", "web", "both"] },
  ],
  legal: [
    { name: "kind", kind: "select", options: ["terms", "privacy", "cookies", "legal_notice"], required: true },
    { name: "body", kind: "i18n", long: true, required: true },
    { name: "requires_reaccept", kind: "boolean" },
  ],
  cities: [
    { name: "name", kind: "i18n", required: true },
    { name: "country", kind: "text", pattern: "^[A-Z]{2}$", required: true },
    { name: "timezone", kind: "text", required: true },
    { name: "is_suggested", kind: "boolean" },
  ],
};

/** Données vides d'un nouveau contenu (texte français à compléter). */
export function emptyData(type: ContentType): Record<string, unknown> {
  const data: Record<string, unknown> = {};
  for (const f of CONTENT_FIELDS[type]) {
    if (f.kind === "i18n") data[f.name] = { fr: "" };
    else if (["tags", "multi", "ingredients", "components", "steps", "workout_steps", "program_days"].includes(f.kind)) data[f.name] = [];
    else if (f.kind === "ref" && f.multiple) data[f.name] = [];
    else if (f.kind === "boolean") data[f.name] = false;
    else if (f.kind === "rule") data[f.name] = { metric: "steps", operator: "gte", threshold: 8000, period: "day" };
    else if (f.kind === "trigger" || f.kind === "json" || f.kind === "subtitles") data[f.name] = {};
  }
  return data;
}

/** Données de la règle d'un challenge ou d'une tâche (RuleDef). */
export const RULE_METRICS = [
  "water_ml",
  "steps",
  "active_minutes",
  "meals_count",
  "protein_g",
  "kcal_within_target",
  "workout_completed",
  "weight_logged",
  "manual",
] as const satisfies readonly components["schemas"]["RuleDef"]["metric"][];
export const RULE_OPERATORS = ["gte", "lte"] as const satisfies readonly components["schemas"]["RuleDef"]["operator"][];
