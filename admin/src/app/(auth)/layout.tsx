import { getTranslations } from "next-intl/server";

import { Logo } from "@/components/Logo";

import { DemoBarSlot } from "../_shell/DemoBarSlot";

/** Écrans de connexion (previews/admin : V.login, V.otp). Pas d'inscription publique. */
export default async function AuthLayout({ children }: LayoutProps<"/">) {
  const t = await getTranslations("admin.auth");
  return (
    <>
      <DemoBarSlot />
      <div className="auth">
        <div className="art">
          <Logo size={40} />
          <div>
            <h1>{t("tagline")}</h1>
            <p style={{ opacity: 0.75, marginTop: 14, maxWidth: 380 }}>{t("tagline_note")}</p>
          </div>
          <span className="small" style={{ opacity: 0.6 }}>
            admin.my-omeo.app
          </span>
        </div>
        <main id="main" className="form">
          <div className="box">{children}</div>
        </main>
      </div>
    </>
  );
}
