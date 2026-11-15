// Génère lib/core/widgets/omeo_icons.g.dart depuis previews/shared/icons.js (source unique des icônes).
// Usage : depuis mobile/, `node tool/gen_icons.mjs`
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import vm from "node:vm";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const source = readFileSync(resolve(root, "../previews/shared/icons.js"), "utf8");

const sandbox = { window: {} };
vm.runInNewContext(source, sandbox);
const { icon, logoMark, brandIcons } = sandbox.window;

// On relit les noms dans l'objet P pour garder l'ordre de la source.
const names = [...source.matchAll(/^ {4}([a-zA-Z]+): '/gm)].map((m) => m[1]);

const inner = (svg) => svg.replace(/^<svg[^>]*>/, "").replace(/<\/svg>$/, "");
const dartString = (s) => "'" + s.replaceAll("\\", "\\\\").replaceAll("'", "\\'").replaceAll("$", "\\$") + "'";
const reserved = new Set(["switch", "case", "default", "in", "is", "new", "null", "true", "false"]);
const ident = (n) => (reserved.has(n) ? n + "Icon" : n);

const lines = [
  "// Généré par tool/gen_icons.mjs depuis previews/shared/icons.js. Ne pas modifier à la main.",
  "// ignore_for_file: public_member_api_docs, constant_identifier_names",
  "",
  "/// Icônes Omeo : trait 1,75 sur une grille de 24, couleur héritée.",
  "enum OmeoIcons {",
  ...names.map((n) => `  ${ident(n)}(${dartString(inner(icon(n)))}),`),
  "  ;",
  "",
  "  const OmeoIcons(this.paths);",
  "",
  "  /// Contenu SVG (chemins) dessiné dans une viewBox de 24.",
  "  final String paths;",
  "}",
  "",
  "/// Logo Omeo (disque croqué), viewBox 64, une seule couleur.",
  `const omeoLogoPath = ${dartString(logoMark(64).match(/ d="([^"]+)"/)[1])};`,
  "",
  "/// Logos tiers en couleurs d'origine (viewBox 24).",
  `const googleLogoSvg = ${dartString(brandIcons.google.replace(/ class="ico"/, ""))};`,
  `const appleLogoSvg = ${dartString(brandIcons.apple.replace(/ class="ico"/, ""))};`,
  `const playLogoSvg = ${dartString(brandIcons.play.replace(/ class="ico"/, ""))};`,
  "",
];

writeFileSync(resolve(root, "lib/core/widgets/omeo_icons.g.dart"), lines.join("\n"));
console.log(`${names.length} icônes générées.`);
