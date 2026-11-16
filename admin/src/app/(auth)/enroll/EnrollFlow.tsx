"use client";

import { useTranslations } from "next-intl";
import { useState, type FormEvent } from "react";

import { confirmEnrollment, startEnrollment, type Enrollment } from "@/app/actions/auth";
import { useCsrf } from "@/components/providers/StaffProvider";

/**
 * Enrôlement TOTP : QR de l'URI otpauth (généré côté serveur, SVG), codes de secours à télécharger,
 * puis confirmation par un premier code.
 */
export function EnrollFlow({ email }: { email: string }) {
  const t = useTranslations();
  const csrf = useCsrf();
  const [setup, setSetup] = useState<Enrollment | null>(null);
  const [saved, setSaved] = useState(false);
  const [code, setCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const message = (problem: string) => (t.has(`errors.${problem}`) ? t(`errors.${problem}`) : t("errors.server_error"));

  async function start() {
    setBusy(true);
    const result = await startEnrollment({ csrf });
    setBusy(false);
    if (result.ok && "data" in result) setSetup(result.data);
    else if (!result.ok) setError(message(result.problem.code));
  }

  function download() {
    if (!setup) return;
    const text = [t("admin.auth.recovery_file_title", { email }), "", ...setup.recoveryCodes].join("\n");
    const url = URL.createObjectURL(new Blob([text], { type: "text/plain;charset=utf-8" }));
    const a = document.createElement("a");
    a.href = url;
    a.download = "omeo-admin-codes-de-secours.txt";
    a.click();
    URL.revokeObjectURL(url);
  }

  async function confirm(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    const result = await confirmEnrollment({ code, csrf });
    setBusy(false);
    if (!result.ok) setError(result.problem.code === "validation_error" ? t("errors.invalid_mfa_code") : message(result.problem.code));
  }

  return (
    <div className="stack">
      <div>
        <h2 style={{ fontSize: 26 }}>{t("admin.auth.enroll_title")}</h2>
        <p className="muted">{t("admin.auth.enroll_subtitle")}</p>
      </div>
      {!setup ? (
        <button type="button" className="btn primary" onClick={start} disabled={busy}>
          {t("admin.auth.enroll_start")}
        </button>
      ) : (
        <>
          <ol className="stack" style={{ paddingInlineStart: 18, margin: 0 }}>
            <li className="stack">
              <span>{t("admin.auth.enroll_step1")}</span>
              {/* SVG du QR généré côté serveur par la bibliothèque qrcode (aucune donnée externe). */}
              <div className="qr" role="img" aria-label="QR code" dangerouslySetInnerHTML={{ __html: setup.qrSvg }} />
              <code className="small">{t("admin.auth.enroll_secret", { secret: setup.secret })}</code>
            </li>
            <li className="stack">
              <span>{t("admin.auth.enroll_step2")}</span>
              <button type="button" className="btn ghost" onClick={download}>
                {t("admin.auth.enroll_download")}
              </button>
              <label className="row small">
                <input type="checkbox" checked={saved} onChange={(e) => setSaved(e.target.checked)} />
                {t("admin.auth.enroll_saved")}
              </label>
            </li>
            <li>
              <form className="stack" onSubmit={confirm}>
                <label htmlFor="enroll-code">{t("admin.auth.enroll_step3")}</label>
                <input
                  id="enroll-code"
                  className="input otp"
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  maxLength={6}
                  value={code}
                  onChange={(e) => setCode(e.target.value.trim())}
                  aria-invalid={error ? true : undefined}
                  required
                />
                <button type="submit" className="btn primary" disabled={busy || !saved || code.length !== 6}>
                  {t("admin.auth.enroll_confirm")}
                </button>
              </form>
            </li>
          </ol>
        </>
      )}
      {error ? (
        <p className="note err" role="alert">
          {error}
        </p>
      ) : null}
    </div>
  );
}
