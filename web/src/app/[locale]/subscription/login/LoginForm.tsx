"use client";

import { useActionState, useId, useState } from "react";

import { FormAlert, fieldProps } from "@/components/forms/FormAlert";
import { Icon } from "@/components/icons/Icon";
import { IDLE, type FormState } from "@/lib/form-state";

import { login } from "../actions";

type Labels = { email: string; password: string; show: string; hide: string; submit: string; pending: string };

export function LoginForm({ labels, next, defaultEmail }: { labels: Labels; next?: string; defaultEmail?: string }) {
  const [state, action, pending] = useActionState<FormState, FormData>(login, IDLE);
  const [visible, setVisible] = useState(false);
  const errorId = useId();

  return (
    <form action={action} className="stack">
      <FormAlert state={state} id={errorId} />
      {next ? <input type="hidden" name="next" value={next} /> : null}
      <div className="f">
        <label htmlFor="login-email">{labels.email}</label>
        <input
          id="login-email"
          className="input"
          type="email"
          required
          autoComplete="username"
          inputMode="email"
          maxLength={254}
          defaultValue={defaultEmail}
          {...fieldProps(state, "email", errorId)}
        />
      </div>
      <div className="f">
        <label htmlFor="login-password">{labels.password}</label>
        <div className="input-group">
          <input
            id="login-password"
            className="input"
            type={visible ? "text" : "password"}
            required
            autoComplete="current-password"
            maxLength={256}
            {...fieldProps(state, "password", errorId)}
          />
          <button type="button" aria-label={visible ? labels.hide : labels.show} aria-pressed={visible} onClick={() => setVisible((v) => !v)}>
            <Icon name="eye" />
          </button>
        </div>
      </div>
      <button type="submit" className="btn block" disabled={pending}>
        {pending ? labels.pending : labels.submit}
      </button>
    </form>
  );
}
