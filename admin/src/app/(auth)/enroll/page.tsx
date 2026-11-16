import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations } from "next-intl/server";

import { getStaff } from "@/server/auth";

import { EnrollFlow } from "./EnrollFlow";

export async function generateMetadata(): Promise<Metadata> {
  return { title: (await getTranslations("admin.auth"))("enroll_title") };
}

/** Première connexion d'un compte invité : enrôlement obligatoire de la double authentification. */
export default async function EnrollPage() {
  const { me } = await getStaff();
  if (me.mfa_enabled) redirect("/");
  return <EnrollFlow email={me.email} />;
}
