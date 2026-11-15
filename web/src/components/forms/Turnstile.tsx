"use client";

import { useEffect, useRef, useState } from "react";

/**
 * Captcha Cloudflare Turnstile. Le jeton est posé dans un champ caché « captcha » et vérifié par
 * l'API (jamais par le site). Le script n'est chargé que sur les pages qui en ont besoin.
 */
type TurnstileApi = {
  render: (el: HTMLElement, options: Record<string, unknown>) => string;
  remove: (id: string) => void;
};

declare global {
  interface Window {
    turnstile?: TurnstileApi;
  }
}

const SCRIPT_ID = "cf-turnstile";
const SCRIPT_SRC = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit";

function loadScript(): Promise<TurnstileApi> {
  return new Promise((resolve, reject) => {
    if (window.turnstile) return resolve(window.turnstile);
    let script = document.getElementById(SCRIPT_ID) as HTMLScriptElement | null;
    if (!script) {
      script = document.createElement("script");
      script.id = SCRIPT_ID;
      script.src = SCRIPT_SRC;
      script.async = true;
      document.head.appendChild(script);
    }
    script.addEventListener("load", () => (window.turnstile ? resolve(window.turnstile) : reject(new Error("turnstile"))));
    script.addEventListener("error", () => reject(new Error("turnstile")));
  });
}

type TurnstileProps = {
  siteKey: string;
  locale: string;
  action: string;
  /** Change à chaque réponse du serveur : un jeton ne sert qu'une fois, le widget est recréé. */
  reset?: unknown;
};

export function Turnstile({ siteKey, locale, action, reset }: TurnstileProps) {
  const container = useRef<HTMLDivElement>(null);
  const [token, setToken] = useState("");
  // Script tiers chargé à la première interaction avec le formulaire, pas à l'ouverture de la page
  const [armed, setArmed] = useState(false);

  useEffect(() => {
    const form = container.current?.closest("form");
    if (!form || armed) return;
    const arm = () => setArmed(true);
    form.addEventListener("focusin", arm, { once: true });
    form.addEventListener("pointerdown", arm, { once: true });
    return () => {
      form.removeEventListener("focusin", arm);
      form.removeEventListener("pointerdown", arm);
    };
  }, [armed]);

  useEffect(() => {
    if (!armed) return;
    let widget: string | undefined;
    let api: TurnstileApi | undefined;
    let cancelled = false;
    loadScript()
      .then((loaded) => {
        if (cancelled || !container.current) return;
        api = loaded;
        widget = loaded.render(container.current, {
          sitekey: siteKey,
          action,
          language: locale,
          appearance: "interaction-only",
          callback: (value: string) => setToken(value),
          "expired-callback": () => setToken(""),
          "error-callback": () => setToken(""),
        });
      })
      .catch(() => setToken(""));
    return () => {
      cancelled = true;
      if (api && widget) api.remove(widget);
      setToken("");
    };
  }, [armed, siteKey, locale, action, reset]);

  return (
    <>
      <div ref={container} />
      <input type="hidden" name="captcha" value={token} />
    </>
  );
}
