import type { ReactNode } from "react";

/**
 * Balises des messages enrichis (`<accent>`, `<b>`) : la mise en forme reste dans le code, le texte
 * dans les traductions.
 */
export const rich = {
  accent: (chunks: ReactNode) => <span className="serif">{chunks}</span>,
  b: (chunks: ReactNode) => <b>{chunks}</b>,
  br: () => <br />,
};

/** Variante sur fond de marque (vert ou noir). */
export const richOnBrand = {
  ...rich,
  accent: (chunks: ReactNode) => <span className="serif accent-on-brand">{chunks}</span>,
};
