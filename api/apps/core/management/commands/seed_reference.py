"""
`manage.py seed_reference [--dry-run]` : données de référence sans lesquelles l'API ne fonctionne pas.

Lancée à chaque démarrage, après `migrate`. Idempotente : crée ce qui manque et n'écrase JAMAIS une valeur existante
(l'admin fait foi après la première installation). Source : api/seeds/reference/ (docs/technique/seeders.md).

Chaque module ajoute sa section dans `SECTIONS` (offres, quotas, points, niveaux, badges…).
"""

from __future__ import annotations

import re
from collections.abc import Callable
from pathlib import Path
from typing import Any, Final

import yaml
from django.conf import settings
from django.core.management.base import BaseCommand, CommandError, CommandParser
from django.db import transaction
from django.utils import timezone

from apps.accounts.models import City, LegalDocument, LegalKind
from apps.billing.models import Plan, QuotaRule
from apps.core import settings_store
from apps.core.models import Setting

SEED_DIR: Final = Path(settings.BASE_DIR) / "seeds" / "reference"
_HTML_COMMENT: Final = re.compile(r"<!--.*?-->", re.DOTALL)
# Mention à compléter : [texte] qui n'est pas un lien Markdown [texte](url).
_PLACEHOLDER: Final = re.compile(r"\[[^\]\n]+\](?!\()")
_LEGAL_TITLES: Final[dict[str, dict[str, str]]] = {
    LegalKind.TERMS: {"fr": "Conditions générales d'utilisation", "en": "Terms of use"},
    LegalKind.PRIVACY: {"fr": "Politique de confidentialité", "en": "Privacy policy"},
    LegalKind.COOKIES: {"fr": "Politique relative aux cookies", "en": "Cookie policy"},
    LegalKind.LEGAL_NOTICE: {"fr": "Mentions légales", "en": "Legal notice"},
}


def _load(name: str) -> Any:
    with (SEED_DIR / name).open(encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def clean_legal_markdown(raw: str) -> str:
    return _HTML_COMMENT.sub("", raw).strip()


def placeholders_in(text: str) -> list[str]:
    return _PLACEHOLDER.findall(text)


class Command(BaseCommand):
    help = "Crée les données de référence manquantes, sans jamais écraser l'existant."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument("--dry-run", action="store_true", help="Affiche ce qui serait créé, sans rien écrire.")

    def handle(self, *args: Any, **options: Any) -> None:
        self.dry_run: bool = options["dry_run"]
        self.created: list[str] = []
        sections: list[tuple[str, Callable[[], None]]] = [
            ("settings", self.seed_settings),
            ("plans", self.seed_plans),
            ("quotas", self.seed_quotas),
            ("cities", self.seed_cities),
            ("legal", self.seed_legal),
        ]
        with transaction.atomic():
            for _name, seeder in sections:
                seeder()
            if self.dry_run:
                transaction.set_rollback(True)
        if not self.dry_run:
            settings_store.invalidate()
        verb = "serait créé" if self.dry_run else "créé"
        for line in self.created:
            self.stdout.write(f"  + {line} ({verb})")
        self.stdout.write(self.style.SUCCESS(f"seed_reference : {len(self.created)} élément(s) {verb}(s)."))

    def _mark(self, label: str) -> None:
        self.created.append(label)

    def seed_settings(self) -> None:
        existing = set(Setting.objects.values_list("key", flat=True))
        for key, value in settings_store.flatten(_load("settings.yaml")).items():
            if key not in existing:
                Setting.objects.create(key=key, value=value)
                self._mark(f"setting {key}")

    def seed_plans(self) -> None:
        for row in _load("plans.yaml"):
            _, created = Plan.objects.get_or_create(
                code=row["code"],
                defaults={
                    "name": row["name"],
                    "price_cents": row.get("price_cents", 0),
                    "interval": row.get("interval", "none"),
                    "is_featured": row.get("is_featured", False),
                    "store_product_ids": row.get("store_product_ids", {}),
                },
            )
            if created:
                self._mark(f"plan {row['code']}")

    def seed_quotas(self) -> None:
        for row in _load("quotas.yaml"):
            _, created = QuotaRule.objects.get_or_create(
                plan_tier=row["plan_tier"],
                feature=row["feature"],
                defaults={"limit": row["limit"], "period": row["period"]},
            )
            if created:
                self._mark(f"quota {row['plan_tier']}.{row['feature']}")

    def seed_cities(self) -> None:
        existing = {(c.country, c.name.get("fr")) for c in City.objects.only("country", "name")}
        for row in _load("cities.yaml"):
            if (row["country"], row["name"]["fr"]) in existing:
                continue
            City.objects.create(
                name=row["name"], country=row["country"], timezone=row["timezone"], is_suggested=True
            )
            self._mark(f"city {row['country']} {row['name']['fr']}")

    def seed_legal(self) -> None:
        for kind in LegalKind.values:
            if LegalDocument.objects.filter(kind=kind, version=1).exists():
                continue
            bodies: dict[str, str] = {}
            for path in sorted((SEED_DIR / "legal").glob(f"{kind}.*.md")):
                locale = path.stem.split(".")[1]
                bodies[locale] = clean_legal_markdown(path.read_text(encoding="utf-8"))
            if not bodies:
                raise CommandError(f"Missing legal text for {kind}")
            remaining = sorted({p for text in bodies.values() for p in placeholders_in(text)})
            if remaining and settings.IS_PRODUCTION:
                raise CommandError(f"{kind}: placeholders left, refusing to publish in production: {remaining}")
            LegalDocument.objects.create(
                kind=kind,
                version=1,
                title=_LEGAL_TITLES[kind],
                body=bodies,
                published_at=timezone.now(),
                requires_reaccept=False,
            )
            self._mark(f"legal {kind} v1")
