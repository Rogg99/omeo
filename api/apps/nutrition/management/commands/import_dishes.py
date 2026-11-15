"""
`manage.py import_dishes <fichier.yaml|dossier> [--update-drafts] [--dry-run]`

Importe les plats d'un pays (méthodologie : docs/technique/seeding-plats.md).

Fichier `seeds/catalog/dishes/<PAYS>.yaml` :

    country: CM
    dishes:
      ndole:                                 # clé stable dans le fichier
        name: { fr: Ndolé, en: Ndole }
        aliases: [ndole, ndolè]
        portion_g: 450                       # facultatif, sinon somme des composants
        components:                          # grammes pour UNE portion standard
          wafct2019:04_017: 150              # <source>:<source_ref> d'un aliment importé
        sources: [« enquête marché Douala 2026-10 »]   # traçabilité, non stockée

Règles :
- Tout le fichier est validé avant d'écrire quoi que ce soit (aliments introuvables, grammes, pays, langues).
- Les plats créés sont en BROUILLON : une autre personne relit et publie (quatre yeux, D27).
- Clé d'un plat : (pays, nom français). Un plat existant n'est jamais modifié, sauf `--update-drafts` qui remplace
  la composition d'un plat encore en brouillon (un plat publié se corrige dans l'admin).
- Les nutriments viennent toujours des aliments (`refresh_dish`), jamais du fichier.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any, Final

import yaml
from django.core.management.base import BaseCommand, CommandError, CommandParser
from django.db import transaction

from apps.core.models import ContentStatus
from apps.nutrition import services as nutrition
from apps.nutrition.models import Dish, DishComponent, Food

COUNTRY_RE: Final = re.compile(r"^[A-Z]{2}$")
MAX_COMPONENT_G: Final = Decimal(2000)
MAX_PORTION_G: Final = Decimal(3000)


@dataclass(frozen=True, slots=True)
class DishRow:
    key: str
    name: dict[str, str]
    aliases: list[str]
    portion_g: Decimal
    components: dict[str, Decimal]  # "<source>:<source_ref>" → grammes


def _grams(raw: Any, where: str) -> Decimal:
    try:
        value = Decimal(str(raw))
    except InvalidOperation:
        raise CommandError(f"{where} : quantité invalide {raw!r}") from None
    if not Decimal(0) < value <= MAX_COMPONENT_G:
        raise CommandError(f"{where} : quantité hors bornes ({value} g)")
    return value


def parse_file(path: Path) -> tuple[str, list[DishRow]]:
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    country = str(data.get("country", "")).upper()
    if not COUNTRY_RE.match(country):
        raise CommandError(f"{path.name} : `country` doit être un code ISO 3166-1 alpha-2")
    if path.stem.upper() != country:
        raise CommandError(f"{path.name} : le nom du fichier doit être le code pays ({country}.yaml)")
    rows: list[DishRow] = []
    for key, raw in (data.get("dishes") or {}).items():
        where = f"{path.name} › {key}"
        name = raw.get("name") or {}
        if not name.get("fr") or not name.get("en"):
            raise CommandError(f"{where} : nom `fr` et `en` obligatoires")
        components = {str(ref): _grams(g, f"{where} › {ref}") for ref, g in (raw.get("components") or {}).items()}
        if not components:
            raise CommandError(f"{where} : composition vide")
        portion = Decimal(str(raw["portion_g"])) if "portion_g" in raw else sum(components.values(), Decimal(0))
        if not Decimal(0) < portion <= MAX_PORTION_G:
            raise CommandError(f"{where} : portion hors bornes ({portion} g)")
        aliases = [str(a).strip() for a in raw.get("aliases") or [] if str(a).strip()]
        rows.append(DishRow(str(key), {k: str(v) for k, v in name.items()}, aliases, portion, components))
    names = [r.name["fr"].casefold() for r in rows]
    if len(set(names)) != len(names):
        raise CommandError(f"{path.name} : deux plats portent le même nom français")
    return country, rows


def resolve_foods(refs: set[str]) -> dict[str, Food]:
    """`<source>:<source_ref>` → aliment, en une requête ; échoue en listant toutes les références manquantes."""
    pairs = {}
    for ref in refs:
        source, sep, source_ref = ref.partition(":")
        if not sep or not source or not source_ref:
            raise CommandError(f"Référence d'aliment invalide {ref!r} (attendu <source>:<source_ref>)")
        pairs[ref] = (source, source_ref)
    found = {
        f"{f.source}:{f.source_ref}": f
        for f in Food.objects.filter(
            source__in={s for s, _ in pairs.values()}, source_ref__in={r for _, r in pairs.values()}
        )
    }
    missing = sorted(refs - found.keys())
    if missing:
        raise CommandError("Aliments introuvables (importer d'abord avec import_foods) :\n  " + "\n  ".join(missing))
    return found


class Command(BaseCommand):
    help = "Importe les plats d'un ou plusieurs pays (en brouillon)."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument("path", type=Path, help="Fichier <PAYS>.yaml ou dossier de fichiers.")
        parser.add_argument("--update-drafts", action="store_true", help="Remplace la composition des brouillons.")
        parser.add_argument("--dry-run", action="store_true")

    def handle(self, *args: Any, **options: Any) -> None:
        path: Path = options["path"]
        files = sorted(path.glob("[A-Z][A-Z].yaml")) if path.is_dir() else [path]
        if not files or not all(f.exists() for f in files):
            raise CommandError(f"Aucun fichier <PAYS>.yaml trouvé : {path}")
        parsed = [parse_file(f) for f in files]
        foods = resolve_foods({ref for _, rows in parsed for row in rows for ref in row.components})
        unpublished = sorted(
            {f"{f.source}:{f.source_ref}" for f in foods.values() if f.status != ContentStatus.PUBLISHED}
        )
        if unpublished:
            self.stdout.write(
                self.style.WARNING(f"{len(unpublished)} aliment(s) non publié(s) : à publier avant les plats.")
            )

        counts = {"created": 0, "updated": 0, "skipped": 0}
        with transaction.atomic():
            for country, rows in parsed:
                for row in rows:
                    counts[self._import(country, row, foods, update_drafts=options["update_drafts"])] += 1
            if options["dry_run"]:
                transaction.set_rollback(True)
        prefix = "[simulation] " if options["dry_run"] else ""
        self.stdout.write(
            self.style.SUCCESS(
                f"{prefix}{counts['created']} plat(s) créé(s), {counts['updated']} mis à jour, "
                f"{counts['skipped']} ignoré(s)."
            )
        )

    def _import(self, country: str, row: DishRow, foods: dict[str, Food], *, update_drafts: bool) -> str:
        dish = Dish.objects.filter(country=country, name__fr=row.name["fr"]).first()
        if dish is not None and not (update_drafts and dish.status == ContentStatus.DRAFT):
            return "skipped"
        outcome = "updated" if dish is not None else "created"
        if dish is None:
            dish = Dish(country=country, name=row.name, status=ContentStatus.DRAFT)
        dish.aliases = sorted(set(dish.aliases) | set(row.aliases))
        dish.standard_portion_g = row.portion_g
        dish.save()
        dish.components.all().delete()
        DishComponent.objects.bulk_create(
            DishComponent(dish=dish, food=foods[ref], grams=grams) for ref, grams in row.components.items()
        )
        nutrition.refresh_dish(dish=dish)
        return outcome
