import { cacheLife } from "next/cache";
import { getTranslations } from "next-intl/server";
import QRCode from "qrcode";

import { siteOrigin } from "@/server/env";

/** SVG du QR code, calculé une fois puis mis en cache (aucun calcul côté navigateur). */
async function qrSvg(target: string): Promise<string> {
  "use cache";
  cacheLife("max");
  const svg = await QRCode.toString(target, { type: "svg", margin: 0, errorCorrectionLevel: "M", color: { dark: "#000000ff", light: "#ffffff00" } });
  // Couleur héritée du CSS (token --ink-950 sur .qr) plutôt qu'une valeur en dur.
  return svg.replace(/#000000(ff)?(?![0-9a-f])/gi, "currentColor");
}

/** QR code vers /download, qui renvoie vers le bon store selon le téléphone. */
export async function QrCode() {
  const [t, svg] = await Promise.all([getTranslations("web.store"), qrSvg(`${siteOrigin}/download`)]);
  return (
    // SVG produit par la bibliothèque qrcode à partir d'une URL du site : aucune donnée externe.
    <div className="qr" role="img" aria-label={t("qr_label")} dangerouslySetInnerHTML={{ __html: svg }} />
  );
}
