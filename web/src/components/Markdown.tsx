import type { ComponentProps } from "react";
import ReactMarkdown from "react-markdown";

import { Link } from "@/i18n/navigation";

/**
 * Markdown publié depuis l'admin (FAQ, pages légales), rendu sur le serveur. Pas de HTML brut
 * (react-markdown l'ignore par défaut) ; les liens internes gardent la langue, les liens externes
 * s'ouvrent dans un nouvel onglet.
 */
function MarkdownLink({ href = "", children }: ComponentProps<"a">) {
  if (href.startsWith("/") && !href.startsWith("//")) return <Link href={href}>{children}</Link>;
  if (/^(https?:|mailto:)/.test(href)) {
    return (
      <a href={href} rel="noopener noreferrer" target={href.startsWith("mailto:") ? undefined : "_blank"}>
        {children}
      </a>
    );
  }
  return <>{children}</>;
}

type MarkdownProps = { children: string; headingIds?: boolean };

export function slugify(text: string): string {
  return text
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, "-")
    .replace(/^-|-$/g, "");
}

function textOf(node: unknown): string {
  if (typeof node === "string" || typeof node === "number") return String(node);
  if (Array.isArray(node)) return node.map(textOf).join("");
  return "";
}

export function Markdown({ children, headingIds = false }: MarkdownProps) {
  return (
    <ReactMarkdown
      skipHtml
      components={{
        a: MarkdownLink,
        h2: ({ children: c }) => <h2 id={headingIds ? slugify(textOf(c)) : undefined}>{c}</h2>,
        img: () => null,
      }}
    >
      {children}
    </ReactMarkdown>
  );
}

/** Titres de niveau 2 d'un document Markdown (sommaire des pages légales). */
export function headingsOf(markdown: string): { id: string; title: string }[] {
  return [...markdown.matchAll(/^##\s+(.+)$/gm)].map((m) => {
    const title = (m[1] ?? "").replace(/[*_`]/g, "").trim();
    return { id: slugify(title), title };
  });
}
