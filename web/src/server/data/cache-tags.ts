/** Tags de cache des contenus publiés depuis l'admin, invalidés par le webhook de revalidation. */
export const CACHE_TAGS = {
  plans: "plans",
  faq: "faq",
  legal: "legal",
} as const;

export type CacheTag = (typeof CACHE_TAGS)[keyof typeof CACHE_TAGS];

export const ALL_CACHE_TAGS: readonly CacheTag[] = Object.values(CACHE_TAGS);
