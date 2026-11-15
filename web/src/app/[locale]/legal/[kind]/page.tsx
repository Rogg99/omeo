import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getFormatter, getTranslations } from "next-intl/server";

import { headingsOf, Markdown } from "@/components/Markdown";
import { Link } from "@/i18n/navigation";
import { metadataLocale, pageLocale } from "@/i18n/page";
import { pageMetadata } from "@/lib/seo";
import source from "@/server/data/source";
import type { LegalKind } from "@/server/data/types";
import { siteOrigin } from "@/server/env";

const KINDS: readonly LegalKind[] = ["terms", "privacy", "cookies", "legal_notice"];

function legalKind(value: string): LegalKind | undefined {
  return (KINDS as readonly string[]).includes(value) ? (value as LegalKind) : undefined;
}

export async function generateMetadata({ params }: PageProps<"/[locale]/legal/[kind]">): Promise<Metadata> {
  const locale = await metadataLocale(params);
  const kind = legalKind((await params).kind);
  if (!locale || !kind) return {};
  const doc = await source.content.legal(locale, kind);
  const t = await getTranslations({ locale, namespace: "web.legal_kind" });
  const title = doc.ok ? doc.data.title : t(kind);
  return pageMetadata({ origin: siteOrigin, locale, path: `/legal/${kind}`, title, description: title });
}

/** CGU, confidentialité, cookies et mentions légales : dernière version publiée, avec sa date. */
export default async function LegalPage({ params }: PageProps<"/[locale]/legal/[kind]">) {
  const locale = await pageLocale(params);
  const kind = legalKind((await params).kind);
  if (!kind) notFound();
  const [t, format, doc] = await Promise.all([getTranslations("web"), getFormatter(), source.content.legal(locale, kind)]);
  const headings = doc.ok ? headingsOf(doc.data.body) : [];

  return (
    <div className="wrap legal-layout" style={{ paddingBlock: "var(--space-16) var(--section)" }}>
      <aside className="toc" aria-label={t("legal.documents")}>
        <p className="eyebrow">{t("legal.documents")}</p>
        <nav aria-label={t("legal.documents")}>
          {KINDS.map((k) => (
            <Link key={k} href={`/legal/${k}`} aria-current={k === kind ? "page" : undefined}>
              {t(`legal_kind.${k}`)}
            </Link>
          ))}
        </nav>
        {headings.length > 1 ? (
          <nav aria-label={t("legal.contents")} className="hide-m mt24">
            <p className="eyebrow">{t("legal.contents")}</p>
            {headings.map((h) => (
              <a key={h.id} href={`#${h.id}`}>
                {h.title}
              </a>
            ))}
          </nav>
        ) : null}
      </aside>
      <article>
        <p className="eyebrow">{t("legal.eyebrow")}</p>
        {doc.ok ? (
          <>
            <h1 className="h2 mt16">{doc.data.title}</h1>
            <p className="small muted mt16">
              {t("legal.version", {
                version: doc.data.version,
                date: format.dateTime(new Date(doc.data.published_at), { dateStyle: "long" }),
              })}
            </p>
            <div className="prose mt24">
              <Markdown headingIds>{doc.data.body}</Markdown>
            </div>
          </>
        ) : (
          <>
            <h1 className="h2 mt16">{t(`legal_kind.${kind}`)}</h1>
            <p className="note info mt24">{t("legal.unavailable")}</p>
          </>
        )}
      </article>
    </div>
  );
}
