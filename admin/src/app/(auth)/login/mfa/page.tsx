import type { Metadata } from "next";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { getTranslations } from "next-intl/server";

import { COOKIES, safeNextPath } from "@/server/session-cookies";

import { MfaForm } from "./MfaForm";

export async function generateMetadata(): Promise<Metadata> {
  return { title: (await getTranslations("admin.auth"))("mfa_title") };
}

export default async function MfaPage({ searchParams }: PageProps<"/login/mfa">) {
  const params = await searchParams;
  if (!(await cookies()).has(COOKIES.mfa)) redirect("/login");
  return <MfaForm next={safeNextPath(typeof params.next === "string" ? params.next : undefined)} />;
}
