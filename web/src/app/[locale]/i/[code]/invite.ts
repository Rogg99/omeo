import "server-only";

import { cache } from "react";

import type { Locale } from "@/i18n/routing";
import source from "@/server/data/source";
import type { InviteCheck } from "@/server/data/types";
import { requestContext } from "@/server/request";
import { normalizeInviteCode } from "@/server/stores";

export type Invite = { code: string; check: InviteCheck | undefined };

/** Vérifie un code une seule fois par requête (page, métadonnées et image Open Graph). */
export const loadInvite = cache(async (rawCode: string, locale: Locale): Promise<Invite | undefined> => {
  const code = normalizeInviteCode(decodeURIComponent(rawCode));
  if (!code) return undefined;
  const result = await source.referral.check(code, await requestContext(locale));
  return { code, check: result.ok ? result.data : undefined };
});
