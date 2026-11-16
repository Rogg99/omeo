"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { useTranslations } from "next-intl";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";

import { forgotPassword, login } from "@/app/actions/auth";
import { Icon } from "@/components/icons/Icon";
import { useCsrf } from "@/components/providers/StaffProvider";

const schema = z.object({ email: z.email().max(254), password: z.string().min(1).max(128) });
type Values = z.infer<typeof schema>;

export function LoginForm({ next, reason }: { next: string; reason?: "idle" | "expired" }) {
  const t = useTranslations();
  const csrf = useCsrf();
  const [error, setError] = useState<string | null>(null);
  const [forgot, setForgot] = useState<"closed" | "open" | "sent">("closed");
  const {
    register,
    handleSubmit,
    getValues,
    formState: { errors, isSubmitting },
  } = useForm<Values>({ resolver: zodResolver(schema) });

  async function onSubmit(values: Values) {
    setError(null);
    // Une réussite redirige (second facteur ou enrôlement) : seul un échec revient ici.
    const result = await login({ ...values, next, csrf });
    if (!result.ok) setError(t.has(`errors.${result.problem.code}`) ? t(`errors.${result.problem.code}`) : t("errors.server_error"));
  }

  async function onForgot() {
    const email = getValues("email");
    if (!schema.shape.email.safeParse(email).success) return;
    await forgotPassword({ email, csrf });
    setForgot("sent");
  }

  return (
    <div className="stack">
      <div>
        <h2 style={{ fontSize: 26 }}>{t("admin.auth.login_title")}</h2>
        <p className="muted">{t("admin.auth.login_subtitle")}</p>
      </div>
      {reason ? (
        <p className="note info" role="status">
          {t(reason === "idle" ? "admin.auth.reason_idle" : "admin.auth.reason_expired")}
        </p>
      ) : null}
      <form className="stack" onSubmit={handleSubmit(onSubmit)} noValidate>
        <div className="f">
          <label htmlFor="email">{t("admin.auth.email")}</label>
          <input id="email" type="email" autoComplete="username" aria-invalid={errors.email ? true : undefined} {...register("email")} />
        </div>
        <div className="f">
          <label htmlFor="password">{t("admin.auth.password")}</label>
          <input
            id="password"
            type="password"
            autoComplete="current-password"
            aria-invalid={errors.password ? true : undefined}
            {...register("password")}
          />
        </div>
        {error ? (
          <p className="note err" role="alert">
            {error}
          </p>
        ) : null}
        <button type="submit" className="btn primary" disabled={isSubmitting}>
          {t("admin.auth.submit")}
        </button>
      </form>
      {forgot === "sent" ? (
        <p className="note ok" role="status">
          {t("admin.auth.forgot_sent")}
        </p>
      ) : forgot === "open" ? (
        <button type="button" className="btn ghost" onClick={onForgot}>
          {t("admin.auth.forgot_submit")}
        </button>
      ) : (
        <button type="button" className="btn ghost sm" onClick={() => setForgot("open")}>
          {t("admin.auth.forgot")}
        </button>
      )}
      <p className="note lock">
        <Icon name="shieldCheck" />
        <span>{t("admin.auth.mfa_required_note")}</span>
      </p>
      <p className="faint small">{t("admin.auth.no_signup")}</p>
    </div>
  );
}
