"use client";

import { useActionState, useId, useState, type ReactNode } from "react";

import { FormAlert } from "@/components/forms/FormAlert";
import { Icon } from "@/components/icons/Icon";
import { IDLE, type FormState } from "@/lib/form-state";

import { startCheckout } from "../actions";

export type PlanOption = { code: "plus_monthly" | "plus_annual"; title: string; price: string; detail: string; savings?: string };

type Labels = {
  question: string;
  add: string;
  label: string;
  check: string;
  checking: string;
  /** Gabarit « {label} : {discounted} au lieu de {original} ». */
  valid: string;
  invalid: string;
  remove: string;
  submit: string;
  redirecting: string;
  networkError: string;
};

type Promo = { code: string; message: string };
type PromoResponse = { valid: boolean; label?: string; original?: { formatted?: string }; discounted?: { formatted?: string } };

export function PlanForm({ options, initial, idempotencyKey, labels, footer }: { options: PlanOption[]; initial: PlanOption["code"]; idempotencyKey: string; labels: Labels; footer: ReactNode }) {
  const [state, action, pending] = useActionState<FormState, FormData>(startCheckout, IDLE);
  const [plan, setPlan] = useState(initial);
  const [promoOpen, setPromoOpen] = useState(false);
  const [code, setCode] = useState("");
  const [promo, setPromo] = useState<Promo | null>(null);
  const [promoError, setPromoError] = useState<string | null>(null);
  const [checking, setChecking] = useState(false);
  const errorId = useId();
  const promoId = useId();

  /** Vérifie le code auprès de l'API (prix remisé calculé par l'API, jamais ici). */
  const checkPromo = async (value: string, planCode: PlanOption["code"]) => {
    const trimmed = value.trim();
    if (!trimmed) return;
    setChecking(true);
    setPromoError(null);
    try {
      const response = await fetch("/api/me/billing/promo-check", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ code: trimmed, plan_code: planCode }),
      });
      if (response.status === 401) return window.location.reload();
      const body = (await response.json()) as PromoResponse;
      if (response.ok && body.valid) {
        setPromo({
          code: trimmed,
          message: labels.valid
            .replace("{label}", body.label ?? trimmed)
            .replace("{discounted}", body.discounted?.formatted ?? "")
            .replace("{original}", body.original?.formatted ?? ""),
        });
      } else {
        setPromo(null);
        setPromoError(labels.invalid);
      }
    } catch {
      setPromoError(labels.networkError);
    } finally {
      setChecking(false);
    }
  };

  const choose = (next: PlanOption["code"]) => {
    setPlan(next);
    // La remise dépend de l'offre : elle est vérifiée à nouveau.
    if (promo) void checkPromo(promo.code, next);
  };

  return (
    <form action={action} className="stack mt32">
      <FormAlert state={state} id={errorId} />
      <input type="hidden" name="idempotency_key" value={idempotencyKey} />
      {promo ? <input type="hidden" name="promo_code" value={promo.code} /> : null}
      <fieldset className="stack" style={{ border: 0, padding: 0, margin: 0 }}>
        <legend className="sr-only">{labels.label}</legend>
        {options.map((option) => (
          <label key={option.code} className="option">
            <input type="radio" name="plan_code" value={option.code} checked={plan === option.code} onChange={() => choose(option.code)} />
            <span className="grow">
              <span className="row wrapf" style={{ gap: "var(--space-2)" }}>
                <b style={{ font: "var(--weight-semibold) var(--text-lg) var(--font-display)" }}>{option.title}</b>
                {option.savings ? <span className="tag orange">{option.savings}</span> : null}
              </span>
              <span className="small muted" style={{ display: "block" }}>
                {option.detail}
              </span>
            </span>
            <b style={{ font: "var(--weight-semibold) var(--text-xl) var(--font-display)" }}>{option.price}</b>
          </label>
        ))}
      </fieldset>

      {promoOpen || promo ? (
        <div className="f">
          <label htmlFor={promoId}>{labels.label}</label>
          {promo ? (
            <p className="note ok" role="status">
              <Icon name="check" />
              <span className="grow">{promo.message}</span>
              <button type="button" className="link-btn" onClick={() => { setPromo(null); setCode(""); }}>
                {labels.remove}
              </button>
            </p>
          ) : (
            <div className="row">
              <input
                id={promoId}
                className="input"
                value={code}
                maxLength={40}
                autoCapitalize="characters"
                autoComplete="off"
                aria-invalid={promoError ? true : undefined}
                aria-describedby={promoError ? `${promoId}-error` : undefined}
                onChange={(e) => setCode(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    void checkPromo(code, plan);
                  }
                }}
              />
              <button type="button" className="btn ghost" disabled={checking || !code.trim()} onClick={() => checkPromo(code, plan)}>
                {checking ? labels.checking : labels.check}
              </button>
            </div>
          )}
          {promoError ? (
            <p id={`${promoId}-error`} className="field-error" role="alert">
              {promoError}
            </p>
          ) : null}
        </div>
      ) : (
        <p className="small">
          {labels.question}{" "}
          <button type="button" className="link-btn" onClick={() => setPromoOpen(true)}>
            {labels.add}
          </button>
        </p>
      )}

      <button type="submit" className="btn green block" disabled={pending}>
        <Icon name="lock" />
        {pending ? labels.redirecting : labels.submit}
      </button>
      {footer}
    </form>
  );
}
