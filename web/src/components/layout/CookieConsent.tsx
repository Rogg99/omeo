"use client";

import { useEffect, useState, useSyncExternalStore } from "react";

import { Link } from "@/i18n/navigation";

/**
 * Consentement à la mesure d'audience. Refuser est aussi simple qu'accepter (deux boutons de même
 * poids) ; rien n'est chargé avant un accord. Le choix est gardé 6 mois dans le navigateur.
 */
const KEY = "omeo-consent";
const REOPEN = "omeo:consent-reopen";
const MAX_AGE_MS = 182 * 24 * 60 * 60 * 1000;

type Choice = "granted" | "denied";

function readChoice(): Choice | null {
  try {
    const raw = window.localStorage.getItem(KEY);
    if (!raw) return null;
    const { choice, at } = JSON.parse(raw) as { choice: Choice; at: number };
    return Date.now() - at < MAX_AGE_MS && (choice === "granted" || choice === "denied") ? choice : null;
  } catch {
    return null;
  }
}

const listeners = new Set<() => void>();
const subscribe = (fn: () => void) => {
  listeners.add(fn);
  return () => listeners.delete(fn);
};

function writeChoice(choice: Choice) {
  try {
    window.localStorage.setItem(KEY, JSON.stringify({ choice, at: Date.now() }));
  } catch {
    // Stockage indisponible (navigation privée) : le choix vaut pour la page en cours.
  }
  listeners.forEach((fn) => fn());
}

type Analytics = { provider: "plausible" | "umami"; siteId?: string; domain: string };

function loadAnalytics({ provider, siteId, domain }: Analytics) {
  if (document.getElementById("omeo-stats")) return;
  const script = document.createElement("script");
  script.id = "omeo-stats";
  script.defer = true;
  script.src = "/stats/script.js";
  if (provider === "plausible") {
    script.dataset.domain = domain;
    script.dataset.api = "/stats/event";
  } else {
    if (siteId) script.dataset.websiteId = siteId;
    script.dataset.hostUrl = `${window.location.origin}/stats`;
  }
  document.head.appendChild(script);
}

type Labels = { title: string; body: string; accept: string; refuse: string; more: string };

export function CookieConsent({ labels, analytics }: { labels: Labels; analytics: Analytics }) {
  const choice = useSyncExternalStore(subscribe, readChoice, () => "denied" as const);
  const [reopened, setReopened] = useState(false);

  useEffect(() => {
    const onReopen = () => setReopened(true);
    window.addEventListener(REOPEN, onReopen);
    return () => window.removeEventListener(REOPEN, onReopen);
  }, []);

  useEffect(() => {
    if (choice === "granted") loadAnalytics(analytics);
  }, [choice, analytics]);

  if (choice !== null && !reopened) return null;

  const decide = (value: Choice) => {
    writeChoice(value);
    setReopened(false);
    // Un refus après un accord : la page est rechargée pour décharger le script de mesure.
    if (value === "denied" && document.getElementById("omeo-stats")) window.location.reload();
  };

  return (
    <section className="cookie" role="region" aria-labelledby="cookie-title">
      <h2 id="cookie-title" style={{ fontSize: "var(--text-lg)" }}>
        {labels.title}
      </h2>
      <p className="small muted mt8">{labels.body}</p>
      <div className="row mt16">
        <button type="button" className="btn sm ghost" onClick={() => decide("denied")}>
          {labels.refuse}
        </button>
        <button type="button" className="btn sm" onClick={() => decide("granted")}>
          {labels.accept}
        </button>
      </div>
      <Link className="xs faint" href="/legal/cookies" style={{ display: "inline-flex", minBlockSize: "var(--size-touch-target)", alignItems: "center" }}>
        {labels.more}
      </Link>
    </section>
  );
}

export function ManageCookiesButton({ label }: { label: string }) {
  return (
    <button type="button" className="link-btn" style={{ textDecoration: "none" }} onClick={() => window.dispatchEvent(new Event(REOPEN))}>
      {label}
    </button>
  );
}
