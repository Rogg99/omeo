/**
 * Catalogue de traductions Omeo (source unique : shared/i18n/<langue>.json, ICU MessageFormat).
 *
 *   pnpm --dir shared build:i18n            génère les fichiers des apps, signale les traductions manquantes
 *   pnpm --dir shared build:i18n --strict   échoue s'il manque une traduction (CI de release)
 *
 * Espaces de noms : common + errors sont partagés ; app → mobile, web → site, admin → back-office.
 * Sorties (ne jamais les modifier à la main) :
 *   mobile/lib/core/l10n/arb/app_<lang>.arb   (flutter gen_l10n ; clés en camelCase)
 *   web/messages/<lang>.json                  (next-intl ; clés imbriquées)
 *   admin/messages/<lang>.json                (next-intl)
 *
 * Contrôles :
 *   - toutes les clés de fr.json (source) sont des messages ICU valides ;
 *   - chaque traduction a les mêmes variables que le français ;
 *   - aucune clé n'existe dans une langue sans exister en français ;
 *   - sous-ensemble ICU autorisé : {arg}, {n, number}, {n, plural, …}, {x, select, …}. Pas de date/heure :
 *     le client formate (intl) et passe une chaîne. Pour Flutter, {n, number} devient {n} + format décimal.
 */
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parse, TYPE } from "@formatjs/icu-messageformat-parser";

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, "..");
const LOCALES = ["fr", "en", "es", "pt", "ar", "zh", "ja", "de"];
const SOURCE = "fr";
const FALLBACK = ["en", "fr"]; // ordre de repli (docs/produit/features/10)
const TARGETS = {
  mobile: ["common", "errors", "app"],
  web: ["common", "errors", "web"],
  admin: ["common", "errors", "admin"],
};
const strict = process.argv.includes("--strict");

function flatten(obj, prefix = "") {
  return Object.entries(obj).reduce((acc, [k, v]) => {
    const key = prefix ? `${prefix}.${k}` : k;
    if (typeof v === "string") acc[key] = v;
    else Object.assign(acc, flatten(v, key));
    return acc;
  }, {});
}

function unflatten(flat) {
  const out = {};
  for (const [key, value] of Object.entries(flat)) {
    const parts = key.split(".");
    let node = out;
    parts.slice(0, -1).forEach((p) => (node = node[p] ??= {}));
    node[parts.at(-1)] = value;
  }
  return out;
}

/** Variables d'un message ICU, avec leur type pour Flutter. */
function variables(message, key, locale) {
  let ast;
  try {
    ast = parse(message, { ignoreTag: true });
  } catch (e) {
    throw new Error(`[${locale}] ${key} : message ICU invalide (${e.message})`);
  }
  const vars = {};
  const walk = (nodes) => {
    for (const n of nodes) {
      if (n.type === TYPE.argument) vars[n.value] ??= "String";
      if (n.type === TYPE.number) vars[n.value] = "number";
      if (n.type === TYPE.date || n.type === TYPE.time) {
        throw new Error(`[${locale}] ${key} : pas de date ICU dans un message ; le client formate la date et la passe en texte`);
      }
      if (n.type === TYPE.plural) {
        vars[n.value] = vars[n.value] === "number" ? "number" : "int";
        Object.values(n.options).forEach((o) => walk(o.value));
      }
      if (n.type === TYPE.select) {
        vars[n.value] = "String";
        Object.values(n.options).forEach((o) => walk(o.value));
      }
    }
  };
  walk(ast);
  return vars;
}

const camel = (key) => key.replace(/[._]([a-z0-9])/g, (_, c) => c.toUpperCase());

const catalogs = Object.fromEntries(
  await Promise.all(LOCALES.map(async (l) => [l, flatten(JSON.parse(await readFile(`${here}/i18n/${l}.json`, "utf8")))])),
);
const source = catalogs[SOURCE];
const errors = [];
const missing = {};

const sourceVars = Object.fromEntries(Object.entries(source).map(([k, m]) => [k, variables(m, k, SOURCE)]));
for (const locale of LOCALES.filter((l) => l !== SOURCE)) {
  const cat = catalogs[locale];
  for (const key of Object.keys(cat)) {
    if (!(key in source)) errors.push(`[${locale}] ${key} : clé absente du français (source)`);
    else {
      const expected = Object.keys(sourceVars[key]).sort().join(",");
      const got = Object.keys(variables(cat[key], key, locale)).sort().join(",");
      if (expected !== got) errors.push(`[${locale}] ${key} : variables {${got}} au lieu de {${expected}}`);
    }
  }
  missing[locale] = Object.keys(source).filter((k) => !(k in cat));
}

if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}

/** Message résolu avec repli : langue → en → fr. */
const resolveMessage = (locale, key) =>
  [locale, ...FALLBACK].map((l) => catalogs[l][key]).find((m) => m !== undefined);

for (const [app, namespaces] of Object.entries(TARGETS)) {
  const keys = Object.keys(source).filter((k) => namespaces.includes(k.split(".")[0]));
  for (const locale of LOCALES) {
    const messages = Object.fromEntries(keys.map((k) => [k, resolveMessage(locale, k)]));
    if (app === "mobile") {
      const arb = { "@@locale": locale };
      for (const [k, m] of Object.entries(messages)) {
        const id = camel(k);
        arb[id] = m.replace(/\{\s*(\w+)\s*,\s*number\s*\}/g, "{$1}");
        if (locale === SOURCE) {
          const vars = sourceVars[k];
          arb[`@${id}`] = Object.keys(vars).length
            ? {
                placeholders: Object.fromEntries(
                  Object.entries(vars).map(([v, type]) => [v, type === "number" ? { type: "num", format: "decimalPattern" } : { type }]),
                ),
              }
            : {};
        }
      }
      const out = resolve(repo, `mobile/lib/core/l10n/arb/app_${locale}.arb`);
      await mkdir(dirname(out), { recursive: true });
      await writeFile(out, `${JSON.stringify(arb, null, 2)}\n`);
    } else {
      const out = resolve(repo, `${app}/messages/${locale}.json`);
      await mkdir(dirname(out), { recursive: true });
      await writeFile(out, `${JSON.stringify(unflatten(messages), null, 2)}\n`);
    }
  }
}

const report = Object.entries(missing)
  .filter(([, keys]) => keys.length)
  .map(([l, keys]) => `  ${l} : ${keys.length} manquante(s) (repli en → fr)`);
console.log(`Traductions générées : ${Object.keys(source).length} clés, ${LOCALES.length} langues.`);
if (report.length) {
  console.log(`Traductions manquantes :\n${report.join("\n")}`);
  if (strict) process.exit(1);
}
