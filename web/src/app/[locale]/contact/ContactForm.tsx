"use client";

import { useActionState, useId, useState, type ReactNode } from "react";

import { FormAlert, fieldProps } from "@/components/forms/FormAlert";
import { Turnstile } from "@/components/forms/Turnstile";
import { Icon } from "@/components/icons/Icon";
import { IDLE, type FormState } from "@/lib/form-state";

import { sendContact } from "./actions";

type Labels = {
  name: string;
  email: string;
  category: string;
  subject: string;
  message: string;
  consent: ReactNode;
  submit: string;
  sending: string;
  successTitle: string;
  successBody: string;
  newMessage: string;
};

type ContactFormProps = {
  labels: Labels;
  categories: { value: string; label: string }[];
  messageMax: number;
  idempotencyKey: string;
  captcha?: { siteKey: string; locale: string };
  locale: string;
};

export function ContactForm({ labels, categories, messageMax, idempotencyKey, captcha, locale }: ContactFormProps) {
  const [state, action, pending] = useActionState<FormState<{ number: string }>, FormData>(sendContact, IDLE);
  const [length, setLength] = useState(0);
  const errorId = useId();
  const counterId = useId();
  const format = new Intl.NumberFormat(locale);


  if (state.status === "success") {
    return (
      <div className="card" role="status">
        <span className="ib">
          <Icon name="check" />
        </span>
        <h2 className="h3 mt16">{labels.successTitle}</h2>
        <p className="muted mt8">{labels.successBody.replace("{number}", state.data.number)}</p>
        <button type="button" className="btn ghost mt24" onClick={() => window.location.reload()}>
          {labels.newMessage}
        </button>
      </div>
    );
  }

  return (
    <form action={action} className="card stack" aria-describedby={errorId}>
      <FormAlert state={state} id={errorId} />
      <input type="hidden" name="idempotency_key" value={idempotencyKey} />
      <div className="grid g2">
        <div className="f">
          <label htmlFor="contact-name">{labels.name}</label>
          <input id="contact-name" className="input" required maxLength={120} autoComplete="name" {...fieldProps(state, "name", errorId)} />
        </div>
        <div className="f">
          <label htmlFor="contact-email">{labels.email}</label>
          <input id="contact-email" className="input" type="email" required maxLength={254} autoComplete="email" inputMode="email" {...fieldProps(state, "email", errorId)} />
        </div>
      </div>
      <div className="f">
        <label htmlFor="contact-category">{labels.category}</label>
        <select id="contact-category" className="input" required defaultValue="question" {...fieldProps(state, "category", errorId)}>
          {categories.map((c) => (
            <option key={c.value} value={c.value}>
              {c.label}
            </option>
          ))}
        </select>
      </div>
      <div className="f">
        <label htmlFor="contact-subject">{labels.subject}</label>
        <input id="contact-subject" className="input" required minLength={3} maxLength={150} {...fieldProps(state, "subject", errorId)} />
      </div>
      <div className="f">
        <label htmlFor="contact-message">{labels.message}</label>
        <textarea
          id="contact-message"
          className="input"
          required
          minLength={10}
          maxLength={messageMax}
          onChange={(e) => setLength(e.target.value.length)}
          {...fieldProps(state, "message", errorId)}
          aria-describedby={[counterId, fieldProps(state, "message", errorId)["aria-describedby"]].filter(Boolean).join(" ")}
        />
        <p id={counterId} className="xs faint" style={{ textAlign: "end" }}>
          {format.format(length)} / {format.format(messageMax)}
        </p>
      </div>
      <label className="check-row">
        <input type="checkbox" name="consent" required {...(state.status === "error" && state.fields.includes("consent") ? { "aria-invalid": true } : {})} />
        <span>{labels.consent}</span>
      </label>
      {captcha ? <Turnstile reset={state} siteKey={captcha.siteKey} locale={captcha.locale} action="contact" /> : null}
      <button type="submit" className="btn green" disabled={pending} aria-disabled={pending}>
        {pending ? labels.sending : labels.submit}
      </button>
    </form>
  );
}
