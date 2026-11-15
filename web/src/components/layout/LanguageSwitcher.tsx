"use client";

import * as DropdownMenu from "@radix-ui/react-dropdown-menu";
import { useLocale } from "next-intl";

import { Icon } from "@/components/icons/Icon";
import { Link, usePathname } from "@/i18n/navigation";
import { LOCALE_NAMES, LOCALES, type Locale } from "@/i18n/routing";

/** Sélecteur de langue : chaque langue est un lien vers la même page dans cette langue. */
export function LanguageSwitcher({ label, chooseLabel }: { label: string; chooseLabel: string }) {
  const locale = useLocale() as Locale;
  const pathname = usePathname();
  return (
    <DropdownMenu.Root modal={false}>
      <DropdownMenu.Trigger className="lang" aria-label={`${locale.toUpperCase()} · ${label}`}>
        <Icon name="globe" />
        <span aria-hidden="true">{locale.toUpperCase()}</span>
      </DropdownMenu.Trigger>
      <DropdownMenu.Portal>
        <DropdownMenu.Content className="menu" align="end" sideOffset={8} aria-label={chooseLabel}>
          {LOCALES.map((l) => (
            <DropdownMenu.Item key={l} asChild>
              <Link href={pathname} locale={l} hrefLang={l} lang={l} aria-current={l === locale ? "true" : undefined}>
                {LOCALE_NAMES[l]}
              </Link>
            </DropdownMenu.Item>
          ))}
        </DropdownMenu.Content>
      </DropdownMenu.Portal>
    </DropdownMenu.Root>
  );
}
