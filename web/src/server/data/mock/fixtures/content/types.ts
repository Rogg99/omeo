import type { ComparisonRow, FaqCategory, LegalKind } from "../../../types";

/**
 * Contenus traduits renvoyés par l'API selon Accept-Language. Ils sont publiés depuis l'admin ;
 * les fixtures en reprennent la forme exacte, dans chaque langue.
 */
export type LocalizedContent = {
  planNames: { free: string; plus_annual: string; plus_monthly: string };
  comparison: ComparisonRow[];
  faq: FaqCategory[];
  legal: Record<LegalKind, { title: string; version: number; published_at: string; body: string }>;
  promoLabel: string;
};
