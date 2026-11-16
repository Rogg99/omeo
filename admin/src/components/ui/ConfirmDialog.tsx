"use client";

import * as Dialog from "@radix-ui/react-dialog";
import { useTranslations } from "next-intl";
import { useId, useState, type FormEvent, type ReactNode } from "react";

/** Motif : de 3 à 500 caractères, enregistré dans l'audit (controle-acces.md). */
export const REASON_MIN = 3;
export const REASON_MAX = 500;

/**
 * Confirmation d'une action : motif obligatoire facultatif, confirmation forte en tapant un nom ou
 * un email (suppression, suspension, remboursement complet). `onConfirm` renvoie vrai pour fermer.
 */
export function ConfirmDialog({
  trigger,
  title,
  description,
  confirmLabel,
  danger = false,
  requireReason = false,
  confirmValue,
  children,
  canConfirm = true,
  onConfirm,
}: {
  trigger: ReactNode;
  title: string;
  description?: ReactNode;
  confirmLabel: string;
  danger?: boolean;
  requireReason?: boolean;
  /** Texte à recopier pour confirmer (nom, email). */
  confirmValue?: string;
  /** Champs supplémentaires (nombre de jours, montant…). */
  children?: ReactNode;
  canConfirm?: boolean;
  onConfirm: (reason: string) => Promise<boolean>;
}) {
  const t = useTranslations();
  const id = useId();
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState("");
  const [typed, setTyped] = useState("");
  const [busy, setBusy] = useState(false);

  const reasonOk = !requireReason || (reason.trim().length >= REASON_MIN && reason.length <= REASON_MAX);
  const typedOk = !confirmValue || typed.trim().toLowerCase() === confirmValue.toLowerCase();

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (!reasonOk || !typedOk || !canConfirm) return;
    setBusy(true);
    const done = await onConfirm(reason.trim());
    setBusy(false);
    if (done) {
      setOpen(false);
      setReason("");
      setTyped("");
    }
  }

  return (
    <Dialog.Root open={open} onOpenChange={setOpen}>
      <Dialog.Trigger asChild>{trigger}</Dialog.Trigger>
      <Dialog.Portal>
        <Dialog.Overlay className="scrim" />
        <Dialog.Content className="dialog" aria-describedby={description ? `${id}-desc` : undefined}>
          <Dialog.Title asChild>
            <h2>{title}</h2>
          </Dialog.Title>
          {description ? (
            <div id={`${id}-desc`} className="muted">
              {description}
            </div>
          ) : null}
          <form className="stack" onSubmit={submit}>
            {children}
            {requireReason ? (
              <div className="f">
                <label htmlFor={`${id}-reason`}>{t("admin.common.reason")}</label>
                <textarea
                  id={`${id}-reason`}
                  value={reason}
                  maxLength={REASON_MAX}
                  onChange={(e) => setReason(e.target.value)}
                  aria-describedby={`${id}-reason-hint`}
                  required
                />
                <span id={`${id}-reason-hint`} className="hint">
                  {t("admin.common.reason_hint")}
                </span>
              </div>
            ) : null}
            {confirmValue ? (
              <div className="f">
                <label htmlFor={`${id}-typed`}>{t("admin.common.type_to_confirm", { value: confirmValue })}</label>
                <input id={`${id}-typed`} value={typed} onChange={(e) => setTyped(e.target.value)} autoComplete="off" required />
              </div>
            ) : null}
            <div className="foot">
              <Dialog.Close asChild>
                <button type="button" className="btn ghost">
                  {t("common.action.cancel")}
                </button>
              </Dialog.Close>
              <button
                type="submit"
                className={`btn ${danger ? "danger" : "primary"}`}
                disabled={busy || !reasonOk || !typedOk || !canConfirm}
              >
                {confirmLabel}
              </button>
            </div>
          </form>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
