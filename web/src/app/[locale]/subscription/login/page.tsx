import { redirect } from "next/navigation";
import { getTranslations } from "next-intl/server";

import { AppleIcon, GoogleIcon, Icon } from "@/components/icons/Icon";
import { pageLocale } from "@/i18n/page";
import source from "@/server/data/source";
import { appleSignInEnabled, googleSignInEnabled } from "@/server/env";
import { requestContext } from "@/server/request";
import { readSession } from "@/server/session";
import { safeNextPath } from "@/server/session-cookies";

import { Steps } from "../Steps";
import { LoginForm } from "./LoginForm";

const SOCIAL_ERRORS = new Set(["social_no_account", "social_failed"]);

/** Étape 1 : connexion au compte Omeo (celui de l'app). */
export default async function LoginPage({ params, searchParams }: PageProps<"/[locale]/subscription/login">) {
  const locale = await pageLocale(params);
  const [t, tm, query, session] = await Promise.all([
    getTranslations("web.subscription"),
    getTranslations("web.mock"),
    searchParams,
    requestContext(locale).then(readSession),
  ]);
  if (session) redirect(`/${locale}/subscription`);

  const next = typeof query.next === "string" ? safeNextPath(query.next, "") || undefined : undefined;
  const error = typeof query.error === "string" && SOCIAL_ERRORS.has(query.error) ? (query.error as "social_no_account" | "social_failed") : undefined;
  const demo = source.demo;
  const google = googleSignInEnabled || Boolean(demo);
  const apple = appleSignInEnabled || Boolean(demo);
  const startUrl = (provider: string) => `/auth/${provider}/start?locale=${locale}${next ? `&next=${encodeURIComponent(next)}` : ""}`;

  return (
    <>
      <Steps current={0} />
      <h1 className="h2 mt32">{t("login_title")}</h1>
      <p className="lead mt16">{t("login_lead")}</p>

      {query.expired ? (
        <p className="note warn mt24" role="status">
          <Icon name="info" />
          <span>{t("session_expired")}</span>
        </p>
      ) : null}
      {error ? (
        <p className="note danger mt24" role="alert">
          <Icon name="alert" />
          <span>{t(error)}</span>
        </p>
      ) : null}

      <div className="card stack mt32">
        {google || apple ? (
          <>
            {google ? (
              <a className="btn ghost block" href={startUrl("google")}>
                <GoogleIcon />
                {t("google")}
              </a>
            ) : null}
            {apple ? (
              <a className="btn block" href={startUrl("apple")}>
                <AppleIcon />
                {t("apple")}
              </a>
            ) : null}
            <p className="center small faint" role="separator">
              {t("or")}
            </p>
          </>
        ) : null}
        <LoginForm
          next={next}
          labels={{
            email: t("email"),
            password: t("password"),
            show: t("show_password"),
            hide: t("hide_password"),
            submit: t("login_submit"),
            pending: t("login_pending"),
          }}
        />
        <p className="small muted">{t("forgot")}</p>
        <p className="small muted">{t("no_account")}</p>
      </div>

      {demo && source.demoPassword ? (
        <section className="card soft mt32" aria-labelledby="demo-accounts">
          <h2 id="demo-accounts" className="h3">
            {tm("accounts_title")}
          </h2>
          <p className="small muted mt8">{tm("accounts_hint", { password: source.demoPassword })}</p>
          <ul className="list mt16">
            {demo.accounts().map((a) => (
              <li key={a.email}>
                <code translate="no">{a.email}</code>
                <span className="small muted">{tm("scenario", { scenario: a.scenario })}</span>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
    </>
  );
}
