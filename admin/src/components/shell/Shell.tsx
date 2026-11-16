"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useTranslations } from "next-intl";
import { useEffect, useMemo, useState, useSyncExternalStore, type ReactNode } from "react";

import { logout } from "@/app/actions/auth";
import { Icon } from "@/components/icons/Icon";
import { Logo } from "@/components/Logo";
import { useCsrf, useStaff } from "@/components/providers/StaffProvider";
import { activeHref, visibleNavigation } from "@/lib/navigation";

import { CommandPalette } from "./CommandPalette";
import { StepUpBadge } from "./StepUpBadge";

const COLLAPSED_KEY = "omeo-admin-side-collapsed";
const collapsedListeners = new Set<() => void>();

/** Préférence « barre repliée », mémorisée dans le navigateur (simple confort, sans enjeu). */
function readCollapsed(): boolean {
  try {
    return localStorage.getItem(COLLAPSED_KEY) === "1";
  } catch {
    return false;
  }
}

function writeCollapsed(value: boolean) {
  try {
    localStorage.setItem(COLLAPSED_KEY, value ? "1" : "0");
  } catch {
    // Préférence non mémorisée : l'état reste celui de la session.
  }
  collapsedListeners.forEach((l) => l());
}

function subscribeCollapsed(listener: () => void) {
  collapsedListeners.add(listener);
  return () => collapsedListeners.delete(listener);
}

/** Barre latérale repliable (menu filtré par permission), barre du haut, ⌘K. */
export function Shell({ children }: { children: ReactNode }) {
  const t = useTranslations("admin");
  const { staff, can } = useStaff();
  const csrf = useCsrf();
  const pathname = usePathname();
  const router = useRouter();
  const groups = useMemo(() => visibleNavigation(can), [can]);
  const items = useMemo(() => groups.flatMap((g) => g.items), [groups]);
  const active = activeHref(pathname, items);
  const collapsed = useSyncExternalStore(subscribeCollapsed, readCollapsed, () => false);
  // Tiroir (tablette) ouvert pour une page donnée : il se referme de lui-même à la navigation.
  const [openOn, setOpenOn] = useState<string | null>(null);
  const open = openOn === pathname;
  const setOpen = (fn: (o: boolean) => boolean) => setOpenOn(fn(open) ? pathname : null);
  const [palette, setPalette] = useState(false);

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setPalette((p) => !p);
      }
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  function toggleCollapsed() {
    writeCollapsed(!collapsed);
  }

  const initials = staff.name
    .split(/\s+/)
    .map((w) => w[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  return (
    <div className="app" data-collapsed={collapsed} data-open={open}>
      <aside className="side" aria-label={t("a11y.open_menu")}>
        <div className="brand">
          <Logo size={28} withText={!collapsed} />
          <span className="env">Admin</span>
        </div>
        <nav>
          {groups.map((group) => (
            <div key={group.label}>
              <div className="grp">{t(`nav.${group.label}`)}</div>
              {group.items.map((item) => {
                const badge = item.badge === "approvals" ? staff.pendingApprovals : 0;
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    aria-current={active === item.href ? "page" : undefined}
                    title={collapsed ? t(`nav.${item.label}`) : undefined}
                    style={{ position: "relative" }}
                  >
                    <Icon name={item.icon} />
                    <span className="label">{t(`nav.${item.label}`)}</span>
                    {badge > 0 ? (
                      <span className="n" aria-label={t("shell.pending_badge", { count: badge })}>
                        {badge}
                      </span>
                    ) : null}
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>
        <button type="button" className="collapse" onClick={toggleCollapsed} aria-pressed={collapsed}>
          <Icon name={collapsed ? "chevR" : "chevL"} />
          <span className="label">{t(collapsed ? "a11y.expand_menu" : "a11y.collapse_menu")}</span>
        </button>
      </aside>
      <div className="main">
        <header className="top">
          <button type="button" className="icon-b menu-toggle" onClick={() => setOpen((o) => !o)} aria-label={t("a11y.open_menu")} aria-expanded={open}>
            <Icon name="list" />
          </button>
          <button type="button" className="search-trigger" onClick={() => setPalette(true)}>
            <Icon name="search" />
            <span>{t("shell.search")}</span>
            <kbd>{t("shell.search_shortcut")}</kbd>
          </button>
          <span style={{ flex: 1 }} />
          <StepUpBadge />
          <span className="av" aria-hidden="true">
            {initials}
          </span>
          <span className="small bold" style={{ maxWidth: 160 }}>
            {staff.name}
          </span>
          <form action={() => logout({ csrf })}>
            <button type="submit" className="icon-b" aria-label={t("shell.logout")} title={t("shell.logout")}>
              <Icon name="logout" />
            </button>
          </form>
        </header>
        <main id="main" tabIndex={-1}>
          {children}
        </main>
      </div>
      <CommandPalette
        open={palette}
        onOpenChange={setPalette}
        items={items.map((i) => ({ href: i.href, icon: i.icon, label: t(`nav.${i.label}`) }))}
        canSearchUsers={can("users.view")}
        onNavigate={(href) => {
          setPalette(false);
          router.push(href);
        }}
      />
    </div>
  );
}
