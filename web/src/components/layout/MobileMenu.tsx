"use client";

import { useEffect, useId, useState } from "react";

import { Icon } from "@/components/icons/Icon";
import { usePathname } from "@/i18n/navigation";

import { NavLinks, type NavItem } from "./NavLinks";

type MobileMenuProps = { items: NavItem[]; openLabel: string; closeLabel: string; navLabel: string };

/** Menu des petits écrans : bouton à bascule (aria-expanded), fermé par Échap ou à la navigation. */
export function MobileMenu({ items, openLabel, closeLabel, navLabel }: MobileMenuProps) {
  const [open, setOpen] = useState(false);
  const panelId = useId();
  const pathname = usePathname();

  useEffect(() => setOpen(false), [pathname]);
  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => event.key === "Escape" && setOpen(false);
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open]);

  return (
    <>
      <button
        type="button"
        className="lang only-m"
        aria-expanded={open}
        aria-controls={panelId}
        aria-label={open ? closeLabel : openLabel}
        onClick={() => setOpen((v) => !v)}
      >
        <Icon name={open ? "x" : "plus"} />
      </button>
      <nav id={panelId} className="mobile-panel only-m" aria-label={navLabel} hidden={!open}>
        <NavLinks items={items} onNavigate={() => setOpen(false)} />
      </nav>
    </>
  );
}
