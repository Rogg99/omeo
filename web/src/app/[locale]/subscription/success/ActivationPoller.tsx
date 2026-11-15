"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

/** Intervalle et durée de l'attente de l'activation (webhook de l'agrégateur). */
export const POLL_INTERVAL_MS = 2_000;
export const POLL_TIMEOUT_MS = 30_000;

/**
 * Interroge /me/subscription (via /api) jusqu'à ce que l'API confirme l'abonnement web
 * (can_manage = "web"), puis recharge la page serveur qui affiche le récapitulatif.
 */
export function ActivationPoller({ slowMessage, checkAgain }: { slowMessage: string; checkAgain: string }) {
  const router = useRouter();
  const [attempt, setAttempt] = useState(0);
  const [slow, setSlow] = useState(false);

  useEffect(() => {
    let stopped = false;
    const started = Date.now();
    const tick = async () => {
      if (stopped) return;
      try {
        const response = await fetch("/api/me/subscription", { cache: "no-store" });
        if (response.status === 401) return router.refresh();
        const body = (await response.json()) as { can_manage?: string };
        if (response.ok && body.can_manage === "web") return router.refresh();
      } catch {
        // Réseau instable : nouvel essai au prochain tour.
      }
      if (Date.now() - started >= POLL_TIMEOUT_MS) return setSlow(true);
      window.setTimeout(tick, POLL_INTERVAL_MS);
    };
    const first = window.setTimeout(tick, POLL_INTERVAL_MS);
    return () => {
      stopped = true;
      window.clearTimeout(first);
    };
  }, [attempt, router]);

  if (!slow) return <div className="spinner mt24" role="presentation" />;
  return (
    <div className="stack mt24">
      <p className="note info" role="status">
        {slowMessage}
      </p>
      <button
        type="button"
        className="btn ghost"
        onClick={() => {
          setSlow(false);
          setAttempt((a) => a + 1);
        }}
      >
        {checkAgain}
      </button>
    </div>
  );
}
