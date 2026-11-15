"use client";

import { useActionState, useId, type ReactNode } from "react";

import { FormAlert, fieldProps } from "@/components/forms/FormAlert";
import { Turnstile } from "@/components/forms/Turnstile";
import { Icon } from "@/components/icons/Icon";
import { Link } from "@/i18n/navigation";
import { IDLE, type FormState } from "@/lib/form-state";

import { confirmDeletion, requestDeletion } from "./actions";

type RequestLabels = { title: string; email: string; note: string; submit: string; sending: string; sentTitle: string; sentBody: string; demoLink: string };

export function DeletionRequestForm({ labels, captcha }: { labels: RequestLabels; captcha?: { siteKey: string; locale: string } }) {
  const [state, action, pending] = useActionState<FormState<{ email: string; demoToken?: string }>, FormData>(requestDeletion, IDLE);
  const errorId = useId();


  if (state.status === "success") {
    return (
      <div className="card" role="status">
        <span className="ib">
          <Icon name="mail" />
        </span>
        <h2 className="h3 mt16">{labels.sentTitle}</h2>
        <p className="muted mt8">{labels.sentBody.replace("{email}", state.data.email)}</p>
        {state.data.demoToken ? (
          <Link className="btn ghost mt24" href={{ pathname: "/delete-account/confirm", query: { token: state.data.demoToken } }}>
            {labels.demoLink}
          </Link>
        ) : null}
      </div>
    );
  }

  return (
    <form action={action} className="card stack">
      <h2 className="h3">{labels.title}</h2>
      <FormAlert state={state} id={errorId} />
      <div className="f">
        <label htmlFor="deletion-email">{labels.email}</label>
        <input id="deletion-email" className="input" type="email" required maxLength={254} autoComplete="email" inputMode="email" {...fieldProps(state, "email", errorId)} />
      </div>
      <p className="small muted">{labels.note}</p>
      {captcha ? <Turnstile reset={state} siteKey={captcha.siteKey} locale={captcha.locale} action="account_deletion" /> : null}
      <button type="submit" className="btn danger" disabled={pending}>
        {pending ? labels.sending : labels.submit}
      </button>
    </form>
  );
}

type ConfirmLabels = { submit: string; sending: string; invalid: string; retry: ReactNode; doneTitle: string; doneBody: string };

export function DeletionConfirmForm({ token, labels }: { token: string; labels: ConfirmLabels }) {
  const [state, action, pending] = useActionState<FormState, FormData>(confirmDeletion, IDLE);
  const errorId = useId();

  if (state.status === "success") {
    return (
      <div className="note ok" role="status">
        <Icon name="check" />
        <div>
          <b>{labels.doneTitle}</b>
          <p>{labels.doneBody}</p>
        </div>
      </div>
    );
  }

  // Lien invalide ou expiré (code de validation du contrat) : nouvelle demande.
  if (state.status === "error" && state.fields.includes("token")) {
    return (
      <div className="stack">
        <p className="note danger" role="alert">
          <Icon name="alert" />
          <span>{labels.invalid}</span>
        </p>
        {labels.retry}
      </div>
    );
  }

  return (
    <form action={action} className="stack">
      <FormAlert state={state} id={errorId} />
      <input type="hidden" name="token" value={token} />
      <button type="submit" className="btn danger" disabled={pending}>
        {pending ? labels.sending : labels.submit}
      </button>
    </form>
  );
}
