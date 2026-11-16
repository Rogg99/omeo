"use client";

import Link from "next/link";
import { useTranslations } from "next-intl";
import { useState, type FormEvent } from "react";

import { verifyMfa } from "@/app/actions/auth";
import { useCsrf } from "@/components/providers/StaffProvider";

/** Second facteur : code TOTP à 6 chiffres, ou code de secours. */
export function MfaForm({ next }: { next: string }) {
  const t = useTranslations();
  const csrf = useCsrf();
  const [recovery, setRecovery] = useState(false);
  const [code, setCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    const result = await verifyMfa({ code, next, csrf });
    setBusy(false);
    if (result.ok) return;
    const { code: problem, detail } = result.problem;
    setError(
      problem === "token_expired"
        ? t("admin.auth.mfa_expired")
        : detail === "invalid_mfa_code"
          ? t("errors.invalid_mfa_code")
          : t.has(`errors.${problem}`)
            ? t(`errors.${problem}`)
            : t("errors.server_error"),
    );
  }

  return (
    <div className="stack">
      <div>
        <h2 style={{ fontSize: 26 }}>{t("admin.auth.mfa_title")}</h2>
        <p className="muted">{t("admin.auth.mfa_subtitle")}</p>
      </div>
      <form className="stack" onSubmit={submit}>
        <div className="f">
          <label htmlFor="code">{t(recovery ? "admin.auth.mfa_recovery_label" : "admin.auth.mfa_code")}</label>
          <input
            id="code"
            className={recovery ? undefined : "otp"}
            inputMode={recovery ? "text" : "numeric"}
            autoComplete="one-time-code"
            maxLength={recovery ? 14 : 6}
            value={code}
            onChange={(e) => setCode(e.target.value.trim())}
            aria-invalid={error ? true : undefined}
            aria-describedby={error ? "code-error" : undefined}
            autoFocus
            required
          />
          {error ? (
            <span id="code-error" className="err" role="alert">
              {error}
            </span>
          ) : null}
        </div>
        <button type="submit" className="btn primary" disabled={busy || code.length < 6}>
          {t("admin.auth.verify")}
        </button>
      </form>
      <button
        type="button"
        className="btn ghost sm"
        onClick={() => {
          setRecovery((r) => !r);
          setCode("");
          setError(null);
        }}
      >
        {t(recovery ? "admin.auth.mfa_totp" : "admin.auth.mfa_recovery")}
      </button>
      <Link href="/login" className="small muted">
        {t("admin.auth.back_to_login")}
      </Link>
    </div>
  );
}
