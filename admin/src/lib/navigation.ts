import type { IconName } from "@/components/icons/Icon";

import { canAny, type Can, type Permission } from "./permissions";

/**
 * Menu de l'admin (previews/admin). Chaque entrée déclare les permissions qui y donnent accès
 * (au moins une) ; la page revérifie côté serveur et l'API reste l'autorité.
 */
export type NavItem = {
  href: string;
  icon: IconName;
  /** Clé de traduction sous admin.nav. */
  label: string;
  permissions: readonly Permission[];
  /** Pastille : nombre de demandes à valider (fourni par GET /admin/me). */
  badge?: "approvals";
};

export type NavGroup = { label: string; items: readonly NavItem[] };

export const NAVIGATION: readonly NavGroup[] = [
  {
    label: "group_pilot",
    items: [
      { href: "/", icon: "dashboard", label: "dashboard", permissions: ["dashboard.product"] },
      { href: "/approvals", icon: "shieldCheck", label: "approvals", permissions: ["approvals.decide"], badge: "approvals" },
    ],
  },
  {
    label: "group_users",
    items: [
      { href: "/users", icon: "users", label: "users", permissions: ["users.view"] },
      { href: "/support", icon: "inbox", label: "support", permissions: ["support.view"] },
    ],
  },
  {
    label: "group_content",
    items: [
      { href: "/content", icon: "layers", label: "content", permissions: ["content.view"] },
      { href: "/translations", icon: "languages", label: "translations", permissions: ["content.view"] },
    ],
  },
  {
    label: "group_ai",
    items: [{ href: "/feedback", icon: "thumbUp", label: "feedback", permissions: ["feedback.view"] }],
  },
  {
    label: "group_revenue",
    items: [
      { href: "/billing", icon: "card", label: "billing", permissions: ["billing.view"] },
      { href: "/billing/plans", icon: "tag", label: "plans", permissions: ["billing.view"] },
      { href: "/billing/promo", icon: "gift", label: "promo", permissions: ["billing.view"] },
    ],
  },
  {
    label: "group_engagement",
    items: [{ href: "/campaigns", icon: "megaphone", label: "campaigns", permissions: ["campaigns.view"] }],
  },
  {
    label: "group_system",
    items: [
      { href: "/settings", icon: "settings", label: "settings", permissions: ["settings.view"] },
      { href: "/team", icon: "shield", label: "team", permissions: ["team.manage"] },
      { href: "/audit", icon: "history", label: "audit", permissions: ["audit.view"] },
    ],
  },
];

/** Menu réduit aux entrées permises ; les groupes vides disparaissent. */
export function visibleNavigation(can: Can): NavGroup[] {
  return NAVIGATION.map((g) => ({ ...g, items: g.items.filter((i) => canAny(can, i.permissions)) })).filter(
    (g) => g.items.length > 0,
  );
}

/** Entrée active pour un chemin : la plus spécifique qui le préfixe. */
export function activeHref(pathname: string, items: readonly NavItem[]): string | undefined {
  return items
    .filter((i) => (i.href === "/" ? pathname === "/" : pathname === i.href || pathname.startsWith(`${i.href}/`)))
    .sort((a, b) => b.href.length - a.href.length)[0]?.href;
}
