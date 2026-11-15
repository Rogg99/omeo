import type { FaqCategory } from "@/server/data/types";

import { Icon } from "./icons/Icon";
import { Markdown } from "./Markdown";

/** Questions-réponses en `<details>` natifs : accessibles au clavier sans JavaScript. */
export function FaqItems({ items, locale }: { items: FaqCategory["items"]; locale: string }) {
  return (
    <div>
      {items.map((item) => (
        <details key={item.id} className="qa" data-faq={`${item.question} ${item.answer}`.toLowerCase()}>
          <summary>
            <span>{item.question}</span>
            <Icon name="plus" />
          </summary>
          <div className="answer">
            <Markdown locale={locale}>{item.answer}</Markdown>
          </div>
        </details>
      ))}
    </div>
  );
}

/** Données structurées FAQPage. */
export function faqJsonLd(categories: FaqCategory[]) {
  return {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: categories.flatMap((c) =>
      c.items.map((item) => ({
        "@type": "Question",
        name: item.question,
        acceptedAnswer: { "@type": "Answer", text: item.answer },
      })),
    ),
  };
}
