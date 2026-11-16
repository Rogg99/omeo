"use client";

import * as Dialog from "@radix-ui/react-dialog";
import { useTranslations } from "next-intl";
import { createContext, useCallback, useContext, useRef, useState, type FormEvent, type ReactNode } from "react";

import { stepUp } from "@/app/actions/auth";

import { useCsrf } from "./StaffProvider";

type RequestStepUp = () => Promise<boolean>;

const StepUpContext = createContext<RequestStepUp | null>(null);

/**
 * Step-up : sur 401 `step_up_required`, une fenêtre demande le code TOTP, appelle
 * POST /auth/mfa/step-up, puis l'appelant rejoue automatiquement l'action (voir useAction).
 */
export function StepUpProvider({ children }: { children: ReactNode }) {
  const t = useTranslations();
  const csrf = useCsrf();
  const [open, setOpen] = useState(false);
  const [code, setCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const resolver = useRef<((ok: boolean) => void) | null>(null);

  const request = useCallback<RequestStepUp>(
    () =>
      new Promise<boolean>((resolve) => {
        resolver.current?.(false);
        resolver.current = resolve;
        setCode("");
        setError(null);
        setOpen(true);
      }),
    [],
  );

  const settle = (ok: boolean) => {
    resolver.current?.(ok);
    resolver.current = null;
    setOpen(false);
  };

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    const result = await stepUp({ code, csrf });
    setBusy(false);
    if (result.ok) settle(true);
    else setError(t(result.problem.detail === "invalid_mfa_code" ? "errors.invalid_mfa_code" : "errors.invalid_credentials"));
  }

  return (
    <StepUpContext.Provider value={request}>
      {children}
      <Dialog.Root open={open} onOpenChange={(next) => !next && settle(false)}>
        <Dialog.Portal>
          <Dialog.Overlay className="scrim" />
          <Dialog.Content className="dialog">
            <Dialog.Title asChild>
              <h2>{t("admin.step_up.title")}</h2>
            </Dialog.Title>
            <Dialog.Description className="muted">{t("admin.step_up.body")}</Dialog.Description>
            <form onSubmit={submit} className="stack">
              <div className="f">
                <label htmlFor="step-up-code">{t("admin.auth.mfa_code")}</label>
                <input
                  id="step-up-code"
                  className="otp"
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  maxLength={12}
                  value={code}
                  onChange={(e) => setCode(e.target.value.trim())}
                  aria-invalid={error ? true : undefined}
                  aria-describedby={error ? "step-up-error" : undefined}
                  autoFocus
                  required
                />
                {error ? (
                  <span id="step-up-error" className="err" role="alert">
                    {error}
                  </span>
                ) : null}
              </div>
              <div className="foot">
                <Dialog.Close asChild>
                  <button type="button" className="btn ghost">
                    {t("common.action.cancel")}
                  </button>
                </Dialog.Close>
                <button type="submit" className="btn primary" disabled={busy || code.length < 6}>
                  {t("admin.step_up.submit")}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </StepUpContext.Provider>
  );
}

export function useStepUp(): RequestStepUp {
  const request = useContext(StepUpContext);
  if (!request) throw new Error("useStepUp doit être utilisé sous <StepUpProvider>.");
  return request;
}
