"use client";

import * as Dialog from "@radix-ui/react-dialog";
import { Command } from "cmdk";
import { useTranslations } from "next-intl";
import { useState } from "react";

import { Icon, type IconName } from "@/components/icons/Icon";

type Item = { href: string; icon: IconName; label: string };

/** Recherche globale (⌘K / Ctrl K) : pages permises, puis recherche d'un utilisateur. */
export function CommandPalette({
  open,
  onOpenChange,
  items,
  canSearchUsers,
  onNavigate,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  items: Item[];
  canSearchUsers: boolean;
  onNavigate: (href: string) => void;
}) {
  const t = useTranslations("admin");
  const [query, setQuery] = useState("");

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="scrim" />
        <Dialog.Content className="dialog cmdk" aria-describedby={undefined}>
          <Dialog.Title className="sr-only">{t("shell.search")}</Dialog.Title>
          <Command label={t("shell.search")}>
            <Command.Input value={query} onValueChange={setQuery} placeholder={t("shell.search")} />
            <Command.List>
              <Command.Empty>{t("shell.search_empty")}</Command.Empty>
              {canSearchUsers && query.trim().length > 1 ? (
                <Command.Group heading={t("nav.users")}>
                  <Command.Item
                    value={`users:${query}`}
                    onSelect={() => onNavigate(`/users?q=${encodeURIComponent(query.trim())}`)}
                  >
                    <Icon name="search" />
                    {t("shell.search_users", { query: query.trim() })}
                  </Command.Item>
                </Command.Group>
              ) : null}
              <Command.Group heading={t("nav.group_pilot")}>
                {items.map((item) => (
                  <Command.Item key={item.href} value={item.label} onSelect={() => onNavigate(item.href)}>
                    <Icon name={item.icon} />
                    {item.label}
                  </Command.Item>
                ))}
              </Command.Group>
            </Command.List>
          </Command>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
