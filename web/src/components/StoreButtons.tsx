import { getTranslations } from "next-intl/server";

import { appStoreUrl, playStoreUrl } from "@/server/stores";

import { AppleIcon, PlayIcon } from "./icons/Icon";

type StoreButtonsProps = { raised?: boolean; inviteCode?: string; id?: string };

/** Boutons Google Play et App Store (liens directs, aucun script). */
export async function StoreButtons({ raised = false, inviteCode, id }: StoreButtonsProps) {
  const t = await getTranslations("web.store");
  const className = `store${raised ? " raised" : ""}`;
  return (
    <div className="row wrapf" id={id}>
      <a className={className} href={playStoreUrl(inviteCode)} aria-label={t("play_label")} data-store="android">
        <PlayIcon />
        <span aria-hidden="true">
          <small>{t("play_small")}</small>
          <b>{t("play_name")}</b>
        </span>
      </a>
      <a className={className} href={appStoreUrl()} aria-label={t("apple_label")} data-store="ios">
        <AppleIcon />
        <span aria-hidden="true">
          <small>{t("apple_small")}</small>
          <b>{t("apple_name")}</b>
        </span>
      </a>
    </div>
  );
}
