"use client";

import { useEffect, useId, useRef, useState } from "react";

import { Icon } from "./icons/Icon";

type FaqSearchProps = {
  label: string;
  placeholder: string;
  /** Message du nombre de résultats, déjà traduit pour chaque nombre possible (index = nombre). */
  results: string[];
  /** Conteneur des questions rendues par le serveur. */
  target: string;
};

export function normalize(text: string): string {
  return text
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase();
}

/** Filtre les questions déjà affichées (aucune requête) ; le nombre de résultats est annoncé. */
export function FaqSearch({ label, placeholder, results, target }: FaqSearchProps) {
  const [count, setCount] = useState<number | null>(null);
  const id = useId();
  const input = useRef<HTMLInputElement>(null);

  /** Filtre le DOM rendu par le serveur (système externe) au fil de la saisie. */
  const search = (value: string) => {
    const root = document.getElementById(target);
    if (!root) return;
    const terms = normalize(value).split(/\s+/).filter(Boolean);
    let visible = 0;
    root.querySelectorAll<HTMLDetailsElement>("[data-faq]").forEach((el) => {
      const match = terms.every((term) => normalize(el.dataset.faq ?? "").includes(term));
      el.hidden = !match;
      if (match) visible += 1;
      if (terms.length > 0 && match) el.open = true;
    });
    root.querySelectorAll<HTMLElement>("[data-faq-group]").forEach((group) => {
      group.hidden = group.querySelector("[data-faq]:not([hidden])") === null;
    });
    setCount(terms.length > 0 ? visible : null);
  };

  // Texte saisi avant l'hydratation (réseau lent) : appliqué dès que le script est prêt.
  useEffect(() => {
    if (input.current?.value) search(input.current.value);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div role="search">
      <label htmlFor={id} className="sr-only">
        {label}
      </label>
      <div className="input-group">
        <input
          id={id}
          className="input"
          type="search"
          ref={input}
          placeholder={placeholder}
          autoComplete="off"
          onChange={(event) => search(event.target.value)}
        />
        <span aria-hidden="true" style={{ position: "absolute", insetInlineEnd: "var(--space-4)", insetBlock: 0, display: "grid", placeItems: "center", color: "var(--text-3)" }}>
          <Icon name="search" />
        </span>
      </div>
      <p className="small muted mt8" aria-live="polite" style={{ minBlockSize: "1.5em" }}>
        {count === null ? "" : (results[Math.min(count, results.length - 1)] ?? "")}
      </p>
    </div>
  );
}
