import type { Metadata } from "next";
import Link from "next/link";
import { getTranslations } from "next-intl/server";

import { Icon, type IconName } from "@/components/icons/Icon";
import { PageHeader } from "@/components/ui/PageHeader";
import { CONTENT_TYPES, type ContentType } from "@/lib/content-types";
import { requirePermission } from "@/server/auth";

export async function generateMetadata(): Promise<Metadata> {
  return { title: (await getTranslations("admin.nav"))("content") };
}

const ICONS: Record<ContentType, IconName> = {
  foods: "utensils",
  dishes: "utensils",
  recipes: "book",
  plants: "sparkles",
  exercises: "pulse",
  workouts: "clock",
  programs: "calendar",
  challenges: "flag",
  badges: "award",
  levels: "trend",
  "point-rules": "list",
  "prevention-tips": "lightbulb",
  faq: "help",
  legal: "file",
  cities: "globe",
};

/** Les 15 types de contenus ; chacun suit brouillon → relecture → publié → archivé. */
export default async function ContentHome() {
  await requirePermission("content.view");
  const t = await getTranslations("admin.content");
  return (
    <div className="page">
      <PageHeader title={t("title")} subtitle={t("subtitle")} />
      <div className="grid g3">
        {CONTENT_TYPES.map((type) => (
          <Link key={type} href={`/content/${type}`} className="card row" style={{ textDecoration: "none" }}>
            <span className="av" aria-hidden="true">
              <Icon name={ICONS[type]} />
            </span>
            <span>
              <b>{t(`type_${type}`)}</b>
              <span className="faint small" style={{ display: "block" }}>
                {t(`type_${type}_hint`)}
              </span>
            </span>
          </Link>
        ))}
      </div>
    </div>
  );
}
