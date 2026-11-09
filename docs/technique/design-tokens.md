# Design tokens

**Source unique :** [shared/tokens/](../../shared/tokens/), au format W3C Design Tokens (DTCG). Les fichiers des apps sont générés à partir de cette source et ne se modifient jamais à la main.

| Fichier source | Contenu |
|---|---|
| `base.json` | Palette (crème, brun, sauge, orange, sémantiques), typographie, rayons, espacements, cible tactile, mouvement |
| `themes/light.json` | Rôles (`bg`, `surface`, `text`, `primary`, `accent`, `danger`…), couleurs des données nutritionnelles, ombres. Les rôles pointent vers la palette |
| `themes/dark.json` | Mêmes clés, valeurs du thème sombre |

```bash
pnpm --dir shared install       # une fois
pnpm --dir shared build:tokens  # après chaque modification
```

| Sortie | Utilisation |
|---|---|
| `admin/src/styles/tokens.css`, `web/src/styles/tokens.css` | Variables CSS : `:root` pour le clair, `[data-theme="dark"]` pour le sombre, et `prefers-color-scheme` quand aucun thème n'est forcé. À brancher sur le thème Tailwind 4 (`@theme inline { --color-bg: var(--bg); … }`) |
| `mobile/lib/core/theme/tokens.g.dart` | `OmeoTokens.light` et `OmeoTokens.dark` (classe `OmeoThemeTokens`), plus les constantes de palette, typographie, rayons, espacements et mouvement. À exposer via une `ThemeExtension` et à mapper sur `ColorScheme` |

## Noms (identiques sur toutes les plateformes)

| Token | CSS | Dart |
|---|---|---|
| `color.role.text-2` | `--text-2` | `text2` |
| `color.data.protein` | `--data-protein` | `dataProtein` |
| `color.palette.sage.700` | `--sage-700` | `sage700` |
| `radius.md` | `--r-md` | `rMd` |
| `space.4` | `--space-4` | `space4` |
| `font.family.display` | `--font-display` | `fontDisplay` |
| `motion.duration.base` | `--duration-base` | `durationBase` |

## Règles
- Les écrans utilisent les **rôles** (`primary`, `surface`, `text-2`…), jamais la palette directement. Seuls les tokens de thème utilisent la palette.
- Les couleurs des données (kcal, protéines, glucides, lipides, fibres, sel, eau) sont les mêmes sur toutes les plateformes.
- Pas de couleur, de rayon ou d'espacement en dur dans le code : un lint le vérifie (stylelint et ESLint côté web et admin, règle personnalisée côté Flutter).
- Les polices sont embarquées : `next/font` en local côté web et admin, assets dans `pubspec.yaml` côté mobile. Jamais Google Fonts au moment de l'exécution.
- Une modification d'un token se fait dans `shared/tokens`, suivie d'un `build:tokens`, et le tout dans un seul commit (source et sorties). La CI régénère les sorties et échoue si elles diffèrent de ce qui est commité.
