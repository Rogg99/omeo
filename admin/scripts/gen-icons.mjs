/**
 * Génère src/components/icons/paths.ts depuis previews/shared/icons.js (jeu d'icônes Omeo,
 * trait 1,75, viewBox 24). Ne garde que les icônes utilisées par l'admin.
 *
 *   pnpm gen:icons
 */
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const source = readFileSync(resolve(here, "../../previews/shared/icons.js"), "utf8");
const block = source.slice(source.indexOf("const P = {") + "const P = {".length, source.indexOf("\n  };"));

const USED = [
  "home", "chart", "trend", "user", "users", "plus", "minus", "x", "check", "chevL", "chevR", "chevD", "search",
  "bell", "help", "settings", "shield", "shieldCheck", "lock", "mail", "eye", "eyeOff", "info", "alert", "card", "tag",
  "gift", "megaphone", "history", "layers", "book", "utensils", "flag", "award", "languages", "thumbUp", "thumbDown",
  "inbox", "dashboard", "download", "upload", "edit", "trash", "refresh", "clock", "send", "file", "filter", "moreH",
  "logout", "key", "ban", "sparkles", "wand", "camera", "pulse", "crown", "dollar", "receipt", "copy", "link", "note",
  "phone", "globe", "lightbulb", "footprints", "list", "sliders", "video", "image", "calendar", "audit", "chevU", "grid", "store"
];

const icons = {};
for (const match of block.matchAll(/^\s+([a-zA-Z0-9]+):\s*'([^']*)'/gm)) icons[match[1]] = match[2];

const missing = USED.filter((name) => !icons[name]);
const kept = USED.filter((name) => icons[name]);
const body = kept.map((name) => `  ${name}: ${JSON.stringify(icons[name])},`).join("\n");
writeFileSync(
  resolve(here, "../src/components/icons/paths.ts"),
  `/**\n * Tracés des icônes Omeo (trait 1,75, viewBox 24), générés depuis previews/shared/icons.js\n * par scripts/gen-icons.mjs. Ne pas modifier à la main.\n */\nexport const ICON_PATHS = {\n${body}\n} as const;\n\nexport type IconName = keyof typeof ICON_PATHS;\n`,
);
console.log(`${kept.length} icônes générées.${missing.length ? ` Absentes du jeu : ${missing.join(", ")}` : ""}`);
