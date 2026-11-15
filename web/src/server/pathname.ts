import "server-only";

import { headers } from "next/headers";

import { isLocale } from "@/i18n/routing";

/** Chemin de la page sans préfixe de langue (« / », « /pricing »…), transmis par src/proxy.ts. */
export async function currentPath(): Promise<string> {
  const raw = (await headers()).get("x-pathname") ?? "/";
  const [, first, ...rest] = raw.split("/");
  const path = isLocale(first) ? `/${rest.join("/")}` : raw;
  return path === "/" || path === "" ? "/" : path.replace(/\/$/, "");
}

export function isCurrent(path: string, href: string): boolean {
  return path === href || (href !== "/" && path.startsWith(`${href}/`));
}
