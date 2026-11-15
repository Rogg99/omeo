import localFont from "next/font/local";

/**
 * Polices auto-hébergées (fichiers @fontsource, sous-ensemble latin ; arabe chargé uniquement en `ar`).
 * `display: swap` : le texte s'affiche tout de suite avec la police système.
 */
export const display = localFont({
  src: "../../node_modules/@fontsource-variable/space-grotesk/files/space-grotesk-latin-wght-normal.woff2",
  weight: "300 700",
  display: "swap",
  variable: "--font-face-display",
  fallback: ["system-ui", "sans-serif"],
});

export const body = localFont({
  src: "../../node_modules/@fontsource-variable/dm-sans/files/dm-sans-latin-wght-normal.woff2",
  weight: "100 1000",
  display: "swap",
  variable: "--font-face-body",
  fallback: ["system-ui", "sans-serif"],
});

export const accent = localFont({
  src: "../../node_modules/@fontsource/instrument-serif/files/instrument-serif-latin-400-italic.woff2",
  weight: "400",
  style: "italic",
  display: "swap",
  variable: "--font-face-accent",
  fallback: ["Georgia", "serif"],
});

export const arabic = localFont({
  src: [
    { path: "../../node_modules/@fontsource/ibm-plex-sans-arabic/files/ibm-plex-sans-arabic-arabic-400-normal.woff2", weight: "400" },
    { path: "../../node_modules/@fontsource/ibm-plex-sans-arabic/files/ibm-plex-sans-arabic-arabic-600-normal.woff2", weight: "600" },
  ],
  display: "swap",
  variable: "--font-face-arabic",
  preload: false,
  fallback: ["system-ui", "sans-serif"],
});
