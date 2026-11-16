import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations } from "next-intl/server";

import { readSession } from "@/server/session";
import { safeNextPath } from "@/server/session-cookies";

import { LoginForm } from "./LoginForm";

export async function generateMetadata(): Promise<Metadata> {
  return { title: (await getTranslations("admin.auth"))("login_title") };
}

export default async function LoginPage({ searchParams }: PageProps<"/login">) {
  const params = await searchParams;
  const next = safeNextPath(typeof params.next === "string" ? params.next : undefined);
  if (await readSession()) redirect(next);
  const reason = params.reason === "idle" || params.reason === "expired" ? params.reason : undefined;
  return <LoginForm next={next} reason={reason} />;
}
