"""
`manage.py import_content <dossier> [--tag-demo]`

Importe les contenus éditoriaux depuis des fichiers YAML, TOUJOURS en brouillon : une autre personne relit et
publie (règle des quatre yeux, D27). Fichiers reconnus : recipes.yaml, plants.yaml, tips.yaml, faq.yaml.
Idempotent : un contenu déjà présent (même nom français) n'est pas recréé.
"""

from __future__ import annotations

from decimal import Decimal
from pathlib import Path
from typing import Any

import yaml
from django.core.management.base import BaseCommand, CommandError, CommandParser
from django.db import transaction

from apps.content.models import FaqItem, Plant, PreventionTip, Recipe, RecipeIngredient, RecipeStep
from apps.content.services import refresh_recipe_nutrients
from apps.core.models import ContentStatus
from apps.nutrition.models import Food


def _load(folder: Path, name: str) -> list[dict[str, Any]]:
    path = folder / name
    if not path.exists():
        return []
    return list(yaml.safe_load(path.read_text(encoding="utf-8")) or [])


class Command(BaseCommand):
    help = "Importe des contenus éditoriaux en brouillon."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument("folder", type=Path)
        parser.add_argument("--tag-demo", action="store_true", help="Étiquette les contenus comme données de démo.")

    @transaction.atomic
    def handle(self, *args: Any, **options: Any) -> None:
        folder: Path = options["folder"]
        if not folder.is_dir():
            raise CommandError(f"{folder} n'est pas un dossier")
        demo: bool = options["tag_demo"]
        counts = {
            "recipes": self._recipes(folder, demo),
            "plants": self._plants(folder, demo),
            "tips": self._tips(folder),
            "faq": self._faq(folder),
        }
        summary = ", ".join(f"{count} {kind}" for kind, count in counts.items())
        self.stdout.write(self.style.SUCCESS(f"import_content (brouillons) : {summary}"))

    def _recipes(self, folder: Path, demo: bool) -> int:
        created = 0
        foods = {f.source_ref: f for f in Food.objects.exclude(source_ref="")}
        for row in _load(folder, "recipes.yaml"):
            if Recipe.objects.filter(name__fr=row["name"]["fr"]).exists():
                continue
            recipe = Recipe.objects.create(
                name=row["name"],
                description=row.get("description", {}),
                country=row.get("country", ""),
                prep_minutes=row.get("prep_minutes", 0),
                cook_minutes=row.get("cook_minutes", 0),
                difficulty=row.get("difficulty", "easy"),
                servings=row.get("servings", 1),
                tags=row.get("tags", []),
                goals=row.get("goals", []),
                is_free=row.get("is_free", False),
                status=ContentStatus.DRAFT,
                is_demo=demo,
            )
            for order, ingredient in enumerate(row.get("ingredients", []), start=1):
                food = foods.get(ingredient.get("food", ""))
                RecipeIngredient.objects.create(
                    recipe=recipe,
                    food=food,
                    grams=Decimal(str(ingredient["grams"])) if ingredient.get("grams") else None,
                    display=ingredient["display"],
                    order=order,
                )
            for order, text in enumerate(row.get("steps", []), start=1):
                RecipeStep.objects.create(recipe=recipe, order=order, text=text)
            refresh_recipe_nutrients(recipe=recipe)
            created += 1
        return created

    def _plants(self, folder: Path, demo: bool) -> int:
        created = 0
        for row in _load(folder, "plants.yaml"):
            if Plant.objects.filter(common_name__fr=row["common_name"]["fr"]).exists():
                continue
            Plant.objects.create(
                common_name=row["common_name"],
                scientific_name=row["scientific_name"],
                tags=row.get("tags", []),
                traditional_use=row.get("traditional_use", {}),
                nutritional_benefits=row.get("nutritional_benefits", {}),
                precautions=row.get("precautions", {}),
                contraindications=row.get("contraindications", []),
                status=ContentStatus.DRAFT,
                is_demo=demo,
            )
            created += 1
        return created

    def _tips(self, folder: Path) -> int:
        created = 0
        for row in _load(folder, "tips.yaml"):
            _tip, was_created = PreventionTip.objects.get_or_create(
                code=row["code"],
                defaults={
                    "topic": row["topic"],
                    "title": row["title"],
                    "body": row["body"],
                    "trigger": row["trigger"],
                    "tier": row.get("tier", "free"),
                    "status": ContentStatus.DRAFT,
                },
            )
            created += int(was_created)
        return created

    def _faq(self, folder: Path) -> int:
        created = 0
        for order, row in enumerate(_load(folder, "faq.yaml")):
            if FaqItem.objects.filter(question__fr=row["question"]["fr"]).exists():
                continue
            FaqItem.objects.create(
                category=row["category"],
                question=row["question"],
                answer=row["answer"],
                audience=row.get("audience", "both"),
                order=order,
                status=ContentStatus.DRAFT,
            )
            created += 1
        return created
