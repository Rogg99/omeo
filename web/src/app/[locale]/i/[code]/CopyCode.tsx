"use client";

import { useState } from "react";

import { Icon } from "@/components/icons/Icon";

/** Copie du code d'invitation (iPhone : aucun paramètre ne survit à l'installation). */
export function CopyCode({ code, copyLabel, copiedLabel }: { code: string; copyLabel: string; copiedLabel: string }) {
  const [copied, setCopied] = useState(false);
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2500);
    } catch {
      setCopied(false);
    }
  };
  return (
    <>
      <button type="button" className="btn sm ghost" onClick={copy}>
        <Icon name={copied ? "check" : "copy"} />
        {copied ? copiedLabel : copyLabel}
      </button>
      <span className="sr-only" aria-live="polite">
        {copied ? copiedLabel : ""}
      </span>
    </>
  );
}
