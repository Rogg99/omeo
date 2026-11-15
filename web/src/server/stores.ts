import { env } from "@/server/env-schema";

/** Plateforme déduite du User-Agent, pour renvoyer vers le bon store. */
export type Platform = "android" | "ios" | "other";

export function platformOf(userAgent: string | null): Platform {
  if (!userAgent) return "other";
  if (/android/i.test(userAgent)) return "android";
  // iPadOS se présente comme un Mac : il est reconnu à son écran tactile côté client uniquement.
  if (/iphone|ipad|ipod/i.test(userAgent)) return "ios";
  return "other";
}

const INVITE_CODE = /^[A-Z0-9]{3,20}$/;

export function normalizeInviteCode(code: string | null | undefined): string | undefined {
  const value = code?.trim().toUpperCase();
  return value && INVITE_CODE.test(value) ? value : undefined;
}

/**
 * Lien Google Play. Le code d'invitation passe par le paramètre `referrer` (Play Install Referrer) :
 * l'app le lit au premier lancement et le remplit automatiquement.
 */
export function playStoreUrl(inviteCode?: string): string {
  const url = new URL("https://play.google.com/store/apps/details");
  url.searchParams.set("id", env.ANDROID_PACKAGE);
  if (inviteCode) url.searchParams.set("referrer", `utm_source=invite&utm_medium=web&invite_code=${inviteCode}`);
  return url.toString();
}

/** Lien App Store (aucun paramètre ne survit à l'installation : le code est copié par l'utilisateur). */
export function appStoreUrl(): string {
  return `https://apps.apple.com/app/id${env.IOS_APP_ID}`;
}

export function storeUrlFor(platform: Platform, inviteCode?: string): string | undefined {
  if (platform === "android") return playStoreUrl(inviteCode);
  if (platform === "ios") return appStoreUrl();
  return undefined;
}
