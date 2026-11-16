import type { components } from "@/lib/api/schema";

/** Les 15 types de contenus administrables (contrat : ContentTypeName). */
export type ContentType = components["schemas"]["ContentTypeName"];
export type ContentStatus = components["schemas"]["ContentStatus"];

export const CONTENT_TYPES = [
  "foods",
  "dishes",
  "recipes",
  "plants",
  "exercises",
  "workouts",
  "programs",
  "challenges",
  "badges",
  "levels",
  "point-rules",
  "prevention-tips",
  "faq",
  "legal",
  "cities",
] as const satisfies readonly ContentType[];

export const CONTENT_STATUSES = ["draft", "review", "published", "archived"] as const satisfies readonly ContentStatus[];

export function isContentType(value: unknown): value is ContentType {
  return typeof value === "string" && (CONTENT_TYPES as readonly string[]).includes(value);
}

export function isContentStatus(value: unknown): value is ContentStatus {
  return typeof value === "string" && (CONTENT_STATUSES as readonly string[]).includes(value);
}

/** Transitions proposées par l'interface (l'API reste l'autorité). */
export const NEXT_STATUSES: Record<ContentStatus, readonly ContentStatus[]> = {
  draft: ["review", "archived"],
  review: ["published", "draft", "archived"],
  published: ["archived"],
  archived: ["draft"],
};
