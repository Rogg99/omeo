import { notFound } from "next/navigation";
import { getTranslations } from "next-intl/server";

import { pageLocale } from "@/i18n/page";
import source from "@/server/data/source";

import { mockSocialLogin } from "../actions";

const PROVIDERS = { google: "Google", apple: "Apple" } as const;

/** Mode démo : remplace l'écran de connexion Google ou Apple. */
export default async function MockSocialPage({ params, searchParams }: PageProps<"/[locale]/subscription/mock-social">) {
  await pageLocale(params);
  if (!source.demo) notFound();
  const [t, query] = await Promise.all([getTranslations("web.mock"), searchParams]);
  const provider = query.provider === "apple" ? "apple" : "google";
  const accounts = source.demo.accounts();

  return (
    <div className="card">
      <span className="tag orange">{t("banner")}</span>
      <h1 className="h2 mt16">{t("social_title", { provider: PROVIDERS[provider] })}</h1>
      <p className="muted mt8">{t("social_lead")}</p>
      <ul className="stack mt24" style={{ listStyle: "none", padding: 0, gap: "var(--space-2)" }}>
        {[...accounts.map((a) => ({ email: a.email, label: t("scenario", { scenario: a.scenario }) })), { email: "", label: t("social_unknown") }].map((a) => (
          <li key={a.email || "unknown"}>
            <form action={mockSocialLogin}>
              <input type="hidden" name="provider" value={provider} />
              <input type="hidden" name="email" value={a.email} />
              <button type="submit" className="option" style={{ inlineSize: "100%", textAlign: "start", font: "inherit", color: "inherit" }}>
                <span className="grow">
                  <b translate="no">{a.email || "—"}</b>
                  <span className="small muted" style={{ display: "block" }}>
                    {a.label}
                  </span>
                </span>
              </button>
            </form>
          </li>
        ))}
      </ul>
    </div>
  );
}
