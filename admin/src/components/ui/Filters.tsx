"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useEffect, useState, useTransition } from "react";

import { Icon } from "@/components/icons/Icon";

/**
 * Filtres dans l'URL (partageables) : chaque changement remplace le paramètre et revient à la
 * page 1. Les Server Components relisent `searchParams` et rappellent l'API.
 */
export function useUrlParams() {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const [pending, startTransition] = useTransition();

  function set(updates: Record<string, string | null | undefined>, resetPage = true) {
    const next = new URLSearchParams(params.toString());
    for (const [key, value] of Object.entries(updates)) {
      if (value === null || value === undefined || value === "") next.delete(key);
      else next.set(key, value);
    }
    if (resetPage && !("page" in updates)) next.delete("page");
    const query = next.toString();
    startTransition(() => router.replace(query ? `${pathname}?${query}` : pathname, { scroll: false }));
  }

  return { params, set, pending };
}

/** Recherche avec temporisation (300 ms), synchronisée avec `?q=`. */
export function SearchFilter({ label, param = "q" }: { label: string; param?: string }) {
  const { params, set } = useUrlParams();
  const current = params.get(param) ?? "";
  const [value, setValue] = useState(current);
  const [synced, setSynced] = useState(current);
  // L'URL a changé sans la saisie (navigation, filtres effacés) : la saisie repart de l'URL.
  if (current !== synced) {
    setSynced(current);
    if (current !== value.trim()) setValue(current);
  }

  useEffect(() => {
    if (value === current) return;
    const timer = window.setTimeout(() => set({ [param]: value.trim() || null }), 300);
    return () => window.clearTimeout(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps -- seule la saisie relance la temporisation
  }, [value]);

  return (
    <label className="search-input">
      <Icon name="search" />
      <span className="sr-only">{label}</span>
      <input type="search" value={value} placeholder={label} onChange={(e) => setValue(e.target.value)} />
    </label>
  );
}

/** Liste déroulante liée à un paramètre d'URL ; l'option vide retire le filtre. */
export function SelectFilter({
  label,
  param,
  options,
  allLabel,
}: {
  label: string;
  param: string;
  options: { value: string; label: string }[];
  allLabel: string;
}) {
  const { params, set } = useUrlParams();
  const value = params.get(param) ?? "";
  return (
    <label>
      <span className="sr-only">{label}</span>
      <select
        className="filter-select"
        data-active={value !== ""}
        value={value}
        onChange={(e) => set({ [param]: e.target.value || null })}
        aria-label={label}
      >
        <option value="">{`${label} : ${allLabel}`}</option>
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {`${label} : ${o.label}`}
          </option>
        ))}
      </select>
    </label>
  );
}

/** Choix exclusif (période…) en boutons segmentés, lié à un paramètre d'URL. */
export function SegmentFilter({
  label,
  param,
  options,
  fallback,
}: {
  label: string;
  param: string;
  options: { value: string; label: string }[];
  fallback: string;
}) {
  const { params, set } = useUrlParams();
  const value = params.get(param) ?? fallback;
  return (
    <div role="radiogroup" aria-label={label} className="row" style={{ gap: 4 }}>
      {options.map((o) => (
        <button
          key={o.value}
          type="button"
          role="radio"
          aria-checked={value === o.value}
          className={`btn sm ${value === o.value ? "" : "ghost"}`}
          onClick={() => set({ [param]: o.value === fallback ? null : o.value })}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}
