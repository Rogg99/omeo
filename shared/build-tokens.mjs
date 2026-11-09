/**
 * Build des design tokens Omeo (source unique : shared/tokens, format W3C DTCG).
 *
 *   pnpm --dir shared build:tokens
 *
 * Génère, sans jamais les éditer à la main :
 *   admin/src/styles/tokens.css          variables CSS, thème clair et thème sombre
 *   web/src/styles/tokens.css            idem
 *   mobile/lib/core/theme/tokens.g.dart  constantes Dart (OmeoTokens.light / OmeoTokens.dark)
 */
import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import StyleDictionary from "style-dictionary";

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, "..");
const HEADER = "Généré par shared/build-tokens.mjs depuis shared/tokens. Ne pas modifier à la main.";

// ── Noms : chemin du token -> nom court, identique sur toutes les plateformes
function shortName(path) {
  const [group, sub, ...rest] = path;
  const key = rest.join("-");
  switch (group) {
    case "color":
      if (sub === "palette") return key;
      if (sub === "role") return key;
      if (sub === "data") return `data-${key}`;
      return `${sub}${key ? `-${key}` : ""}-color`;
    case "font":
      if (sub === "family") return `font-${key}`;
      if (sub === "size") return `text-${key}`;
      return `weight-${key}`;
    case "radius":
      return `r-${sub}`;
    case "motion":
      return sub === "easing" ? (key === "standard" ? "ease" : `ease-${key}`) : `duration-${key}`;
    default:
      return [group, sub, ...rest].join("-");
  }
}

StyleDictionary.registerTransform({
  name: "omeo/name",
  type: "name",
  transform: (token) => shortName(token.path),
});

StyleDictionary.registerTransform({
  name: "omeo/css-value",
  type: "value",
  transitive: true,
  transform: (token) => {
    const v = token.$value ?? token.value;
    const type = token.$type ?? token.type;
    if (v && typeof v === "object" && "value" in v && "unit" in v) return `${v.value}${v.unit}`;
    if (type === "fontFamily" && Array.isArray(v)) return v.map((f) => (f.includes(" ") ? `"${f}"` : f)).join(", ");
    if (type === "cubicBezier" && Array.isArray(v)) return `cubic-bezier(${v.join(", ")})`;
    return v;
  },
});

const cssTransforms = ["omeo/name", "omeo/css-value"];

async function buildCss() {
  const light = new StyleDictionary({
    source: [`${here}/tokens/base.json`, `${here}/tokens/themes/light.json`],
    log: { verbosity: "silent" },
    platforms: {
      css: {
        transforms: cssTransforms,
        buildPath: `${here}/.build/`,
        files: [{ destination: "light.css", format: "css/variables", options: { selector: ":root", outputReferences: true, fileHeader: () => [HEADER] } }],
      },
    },
  });
  const dark = new StyleDictionary({
    source: [`${here}/tokens/base.json`, `${here}/tokens/themes/dark.json`],
    log: { verbosity: "silent" },
    platforms: {
      css: {
        transforms: cssTransforms,
        buildPath: `${here}/.build/`,
        files: [{
          destination: "dark.css",
          format: "css/variables",
          // Seuls les tokens de thème changent en sombre
          filter: (t) => t.filePath.includes("themes"),
          options: { selector: '[data-theme="dark"]', outputReferences: true, fileHeader: () => [HEADER] },
        }],
      },
    },
  });
  await light.buildAllPlatforms();
  await dark.buildAllPlatforms();
  const { readFile } = await import("node:fs/promises");
  const css = [
    await readFile(`${here}/.build/light.css`, "utf8"),
    (await readFile(`${here}/.build/dark.css`, "utf8")).replace(/^\/\*\*[\s\S]*?\*\/\n\n?/, ""),
    `/* Thème « système » : appliqué quand aucun data-theme n'est forcé */\n@media (prefers-color-scheme: dark) {\n  :root:not([data-theme="light"]) {\n${(await readFile(`${here}/.build/dark.css`, "utf8"))
      .split("\n").filter((l) => l.trim().startsWith("--")).map((l) => `  ${l}`).join("\n")}\n  }\n}\n`,
  ].join("\n");
  for (const app of ["admin", "web"]) {
    const out = resolve(repo, app, "src/styles/tokens.css");
    await mkdir(dirname(out), { recursive: true });
    await writeFile(out, css);
  }
}

// ── Dart
function dartColor(hex) {
  const h = hex.replace("#", "");
  return `Color(0xFF${h.toUpperCase()})`;
}
function camel(name) {
  return name.replace(/-([a-z0-9])/g, (_, c) => c.toUpperCase()).replace(/^(\d)/, "n$1");
}
function dartShadows(css) {
  // "0 6px 20px -8px rgba(43, 31, 23, 0.16), 0 2px 6px ..." -> List<BoxShadow>
  return css.split(/,(?![^(]*\))/).map((part) => {
    const m = part.trim().match(/^(-?[\d.]+)(?:px)?\s+(-?[\d.]+)(?:px)?\s+(-?[\d.]+)(?:px)?(?:\s+(-?[\d.]+)(?:px)?)?\s+rgba\(([^)]+)\)$/);
    if (!m) throw new Error(`Ombre non reconnue : ${part}`);
    const [, x, y, blur, spread = "0", rgba] = m;
    const [r, g, b, a] = rgba.split(",").map((s) => Number(s.trim()));
    const color = `Color.fromRGBO(${r}, ${g}, ${b}, ${a})`;
    return `BoxShadow(color: ${color}, offset: Offset(${x}, ${y}), blurRadius: ${blur}, spreadRadius: ${spread})`;
  });
}

async function resolved(theme) {
  const sd = new StyleDictionary({
    source: [`${here}/tokens/base.json`, `${here}/tokens/themes/${theme}.json`],
    log: { verbosity: "silent" },
    platforms: { raw: { transforms: ["omeo/name"] } },
  });
  const { allTokens } = await sd.getPlatformTokens("raw");
  return allTokens;
}

async function buildDart() {
  const light = await resolved("light");
  const dark = await resolved("dark");
  const themed = (tokens) => tokens.filter((t) => t.filePath.includes("themes"));
  const base = light.filter((t) => !t.filePath.includes("themes"));

  const themeClass = (name, tokens) => {
    const colors = themed(tokens).filter((t) => t.$type === "color");
    const shadows = themed(tokens).filter((t) => t.$type === "shadow");
    return [
      `  static const ${name} = OmeoThemeTokens(`,
      ...colors.map((t) => `    ${camel(t.name)}: ${dartColor(t.$value)},`),
      ...shadows.map((t) => `    ${camel(t.name)}: [${dartShadows(t.$value).join(", ")}],`),
      "  );",
    ].join("\n");
  };
  const fields = themed(light);
  const lines = [
    `// ${HEADER}`,
    "// ignore_for_file: public_member_api_docs",
    "import 'package:flutter/painting.dart';",
    "",
    "/// Tokens qui changent selon le thème (rôles, couleurs de données, ombres).",
    "class OmeoThemeTokens {",
    "  const OmeoThemeTokens({",
    ...fields.map((t) => `    required this.${camel(t.name)},`),
    "  });",
    ...fields.map((t) => `  final ${t.$type === "shadow" ? "List<BoxShadow>" : "Color"} ${camel(t.name)};`),
    "}",
    "",
    "/// Tokens communs aux deux thèmes.",
    "abstract final class OmeoTokens {",
    themeClass("light", light),
    themeClass("dark", dark),
    "",
    "  // Palette",
    ...base.filter((t) => t.$type === "color").map((t) => `  static const ${camel(t.name)} = ${dartColor(t.$value)};`),
    "",
    "  // Typographie (familles embarquées dans l'app, voir pubspec.yaml)",
    ...base.filter((t) => t.$type === "fontFamily").map((t) => `  static const ${camel(t.name)} = '${t.$value[0]}';`),
    ...base.filter((t) => t.path[1] === "size").map((t) => `  static const double ${camel(t.name)} = ${t.$value.value};`),
    ...base.filter((t) => t.$type === "fontWeight").map((t) => `  static const ${camel(t.name)} = FontWeight.w${t.$value};`),
    "",
    "  // Rayons, espacements, tailles",
    ...base.filter((t) => t.path[0] === "radius" || t.path[0] === "space" || t.path[0] === "size")
      .map((t) => `  static const double ${camel(t.name)} = ${t.$value.value};`),
    "",
    "  // Mouvement",
    ...base.filter((t) => t.$type === "duration").map((t) => `  static const ${camel(t.name)} = Duration(milliseconds: ${t.$value.value});`),
    ...base.filter((t) => t.$type === "cubicBezier").map((t) => `  static const ${camel(t.name)} = Cubic(${t.$value.join(", ")});`),
    "}",
    "",
  ];
  const out = resolve(repo, "mobile/lib/core/theme/tokens.g.dart");
  await mkdir(dirname(out), { recursive: true });
  await writeFile(out, lines.join("\n").replace("import 'package:flutter/painting.dart';", "import 'package:flutter/animation.dart';\nimport 'package:flutter/painting.dart';"));
}

await buildCss();
await buildDart();
console.log("Tokens générés : admin/src/styles, web/src/styles, mobile/lib/core/theme/tokens.g.dart");
