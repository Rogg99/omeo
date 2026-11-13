"""
`manage.py import_foods <fichier.csv> --source wafct2019 [--publish]`

Importe une table de composition (valeurs pour 100 g de partie comestible).
- Correspondance des colonnes par profil de source (`PROFILES`).
- Sel = sodium × 2,5 (le sodium est donné en mg).
- Chaque aliment garde sa source et son identifiant d'origine (`source`, `source_ref`).
- Réimporter met à jour les valeurs nutritionnelles, JAMAIS les noms ni les autres noms édités dans l'admin.
- Les aliments créés sont en brouillon, sauf `--publish` (catalogue de démo).
"""

from __future__ import annotations

import csv
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any, Final

from django.core.management.base import BaseCommand, CommandError, CommandParser
from django.db import transaction

from apps.core.models import ContentStatus
from apps.nutrition.models import Food, FoodCategory
from apps.nutrition.services import save_food

SALT_PER_SODIUM: Final = Decimal("2.5")


@dataclass(frozen=True, slots=True)
class SourceProfile:
    ref: str
    name_fr: str
    name_en: str
    category: str
    nutrients: dict[str, str]  # champ Food → colonne
    sodium_mg: str
    categories: dict[str, str]  # code de groupe de la source → FoodCategory


PROFILES: Final[dict[str, SourceProfile]] = {
    # FAO/INFOODS West African Food Composition Table 2019 (export CSV des feuilles « 03 NV_sum_39 »).
    "wafct2019": SourceProfile(
        ref="Code",
        name_fr="Nom du produit en Français",
        name_en="Food name in English",
        category="Group",
        nutrients={
            "kcal": "ENERC(kcal)",
            "protein_g": "PROCNT(g)",
            "carbs_g": "CHOAVLDF(g)",
            "sugars_g": "SUGAR(g)",
            "fat_g": "FAT(g)",
            "saturated_fat_g": "FASAT(g)",
            "fiber_g": "FIBTG(g)",
        },
        sodium_mg="NA(mg)",
        categories={
            "01": FoodCategory.CEREALS,
            "02": FoodCategory.TUBERS,
            "03": FoodCategory.LEGUMES,
            "04": FoodCategory.VEGETABLES,
            "05": FoodCategory.FRUITS,
            "06": FoodCategory.OTHER,
            "07": FoodCategory.MEAT,
            "08": FoodCategory.OTHER,
            "09": FoodCategory.FISH,
            "10": FoodCategory.OTHER,
            "11": FoodCategory.OILS,
            "12": FoodCategory.DRINKS,
            "13": FoodCategory.OTHER,
            "14": FoodCategory.SPICES,
        },
    ),
}


def parse_decimal(raw: str | None) -> Decimal:
    """Valeurs des tables : `[1.2]` (estimée), `tr` (traces), vide → 0."""
    if raw is None:
        return Decimal(0)
    cleaned = raw.strip().strip("[]()").replace(",", ".")
    if cleaned in {"", "tr", "-", "na"}:
        return Decimal(0)
    try:
        return Decimal(cleaned).quantize(Decimal("0.01"))
    except InvalidOperation:
        return Decimal(0)


def salt_from_sodium_mg(sodium_mg: Decimal) -> Decimal:
    return (sodium_mg * SALT_PER_SODIUM / 1000).quantize(Decimal("0.01"))


def nutrients_from_row(row: dict[str, str], profile: SourceProfile) -> dict[str, Decimal]:
    values = {field: parse_decimal(row.get(column)) for field, column in profile.nutrients.items()}
    values["salt_g"] = salt_from_sodium_mg(parse_decimal(row.get(profile.sodium_mg)))
    return values


class Command(BaseCommand):
    help = "Importe des aliments depuis une table de composition (CSV)."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument("path", type=Path)
        parser.add_argument("--source", required=True, choices=sorted(PROFILES))
        parser.add_argument("--publish", action="store_true", help="Publie les aliments créés.")

    def handle(self, *args: Any, **options: Any) -> None:
        path: Path = options["path"]
        if not path.exists():
            raise CommandError(f"{path} introuvable")
        source: str = options["source"]
        profile = PROFILES[source]
        created = updated = 0
        with path.open(encoding="utf-8-sig", newline="") as handle, transaction.atomic():
            for row in csv.DictReader(handle):
                ref = (row.get(profile.ref) or "").strip()
                name_fr = (row.get(profile.name_fr) or "").strip()
                if not ref or not name_fr:
                    continue
                nutrients = nutrients_from_row(row, profile)
                food = Food.objects.filter(source=source, source_ref=ref).first()
                if food is None:
                    food = Food(
                        source=source,
                        source_ref=ref,
                        name={"fr": name_fr, "en": (row.get(profile.name_en) or name_fr).strip()},
                        category=profile.categories.get((row.get(profile.category) or "")[:2], FoodCategory.OTHER),
                        status=ContentStatus.PUBLISHED if options["publish"] else ContentStatus.DRAFT,
                    )
                    created += 1
                else:
                    updated += 1
                for field, value in nutrients.items():
                    setattr(food, field, value)
                save_food(food=food)
        self.stdout.write(self.style.SUCCESS(f"import_foods : {created} créé(s), {updated} mis à jour."))
