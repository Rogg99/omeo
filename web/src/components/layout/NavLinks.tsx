"use client";

import { Link, usePathname } from "@/i18n/navigation";

export type NavItem = { href: string; label: string };

/** Liens de navigation, avec la page en cours signalée (aria-current). */
export function NavLinks({ items, className, onNavigate }: { items: NavItem[]; className?: string; onNavigate?: () => void }) {
  const pathname = usePathname();
  return (
    <>
      {items.map((item) => {
        const current = pathname === item.href || (item.href !== "/" && pathname.startsWith(`${item.href}/`));
        return (
          <Link key={item.href} href={item.href} className={className} aria-current={current ? "page" : undefined} onClick={onNavigate}>
            {item.label}
          </Link>
        );
      })}
    </>
  );
}
