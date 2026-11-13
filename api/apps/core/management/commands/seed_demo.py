"""
`manage.py seed_demo [--reset] [--seed 42]` : données de démo identiques aux maquettes (docs/technique/seeders.md).

- Interdite en production.
- Déterministe : graine fixe, dates relatives à aujourd'hui.
- Passe par les VRAIS services (création de compte, objectifs, suspension…), jamais par des insertions directes.
- `--reset` ne supprime que les comptes `@demo.omeo.app` (et, plus tard, les contenus étiquetés `demo`).

Chaque module ajoute sa section (repas, eau, activité, challenges, paiements…) à `SECTIONS`.
"""

from __future__ import annotations

import base64
import hashlib
import random
from dataclasses import dataclass
from datetime import date
from typing import Any, Final

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError, CommandParser
from django.db import transaction
from django.utils import timezone

from apps.accounts import mfa
from apps.accounts import services as accounts
from apps.accounts.models import City, Role, StaffRole, User
from apps.core.audit import RequestMeta

DEMO_DOMAIN: Final = "demo.omeo.app"
DEMO_PASSWORD: Final = "Demo-Omeo-2026!"
DEMO_META: Final = RequestMeta(ip=None, user_agent="seed_demo")
ALL_CONSENTS: Final = [
    {"kind": "terms", "granted": True},
    {"kind": "privacy", "granted": True},
    {"kind": "health_data", "granted": True},
    {"kind": "marketing", "granted": True},
]


@dataclass(frozen=True, slots=True)
class DemoUser:
    slug: str
    first_name: str
    last_name: str
    sex: str
    age: int
    city: str
    height_cm: float
    weight_kg: float
    target_weight_kg: float
    goals: list[str]
    situation: str  # trial, free, plus_monthly, plus_annual, quota_exhausted, new, suspended
    verified: bool = True


DEMO_USERS: Final[tuple[DemoUser, ...]] = (
    DemoUser("awa", "Awa", "Diallo", "female", 30, "Yaoundé", 175, 78.4, 74, ["lose_weight", "eat_balanced", "prevent_diabetes"], "trial"),
    DemoUser("moussa", "Moussa", "Koné", "male", 34, "Abidjan", 178, 84.0, 80, ["lose_weight", "prevent_hypertension"], "free"),
    DemoUser("fatou", "Fatou", "Kane", "female", 27, "Dakar", 165, 61.0, 61, ["eat_balanced"], "plus_monthly"),
    DemoUser("koffi", "Koffi", "Mensah", "male", 29, "Lomé", 181, 72.0, 77, ["gain_muscle"], "plus_annual"),
    DemoUser("aicha", "Aïcha", "Traoré", "female", 41, "Bamako", 162, 70.5, 65, ["lose_weight", "prevent_diabetes"], "quota_exhausted"),
    DemoUser("nouveau", "Nouveau", "Compte", "female", 24, "Cotonou", 168, 60.0, 58, ["eat_balanced"], "new", verified=False),
    DemoUser("suspendu", "Compte", "Suspendu", "male", 38, "Douala", 172, 76.0, 72, ["eat_balanced"], "suspended"),
)

STAFF: Final[tuple[tuple[str, str], ...]] = (
    ("superadmin", Role.SUPERADMIN),
    ("content", Role.CONTENT),
    ("content2", Role.CONTENT),
    ("support", Role.SUPPORT),
    ("finance", Role.FINANCE),
    ("finance2", Role.FINANCE),
    ("moderation", Role.MODERATION),
)


def demo_email(slug: str) -> str:
    return f"{slug}@{DEMO_DOMAIN}"


def demo_totp_secret(slug: str, seed: int) -> str:
    """Secret TOTP déterministe (démo uniquement) : base32 de 20 octets dérivés de la graine."""
    digest = hashlib.sha256(f"omeo-demo-totp:{seed}:{slug}".encode()).digest()[:20]
    return base64.b32encode(digest).decode().rstrip("=")


def birth_date_for(age: int, today: date, rng: random.Random) -> date:
    """Date de naissance déterministe donnant exactement `age` ans aujourd'hui."""
    month, day = rng.randint(1, 12), rng.randint(1, 28)
    year = today.year - age - (1 if (month, day) > (today.month, today.day) else 0)
    return date(year, month, day)


class Command(BaseCommand):
    help = "Données de démo déterministes (interdit en production)."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument("--reset", action="store_true", help="Supprime d'abord les données de démo.")
        parser.add_argument("--seed", type=int, default=42)

    def handle(self, *args: Any, **options: Any) -> None:
        if settings.IS_PRODUCTION:
            raise CommandError("seed_demo est interdite en production.")
        self.seed: int = options["seed"]
        self.rng = random.Random(self.seed)  # noqa: S311 - données de démo, pas de cryptographie
        self.today = timezone.localdate()
        with transaction.atomic():
            if options["reset"]:
                self.reset()
            if User.objects.filter(email__endswith=f"@{DEMO_DOMAIN}").exists():
                self.stdout.write("Données de démo déjà présentes (utiliser --reset pour les recréer).")
                return
            users = self.seed_accounts()
            self.seed_staff()
        self.stdout.write(self.style.SUCCESS(f"seed_demo : {len(users)} comptes et {len(STAFF)} membres du staff."))

    def reset(self) -> None:
        deleted, _ = User.objects.filter(email__endswith=f"@{DEMO_DOMAIN}").delete()
        self.stdout.write(f"Réinitialisation : {deleted} ligne(s) de démo supprimée(s).")

    def _city(self, name: str) -> City | None:
        return City.objects.filter(name__fr=name).first()

    def seed_accounts(self) -> dict[str, User]:
        users: dict[str, User] = {}
        for demo in DEMO_USERS:
            city = self._city(demo.city)
            profile: dict[str, Any] = {
                "first_name": demo.first_name,
                "last_name": demo.last_name,
                "birth_date": birth_date_for(demo.age, self.today, self.rng),
                "sex": demo.sex,
                "height_cm": demo.height_cm,
                "weight_kg": demo.weight_kg,
                "target_weight_kg": demo.target_weight_kg,
                "goals": demo.goals,
                "locale": "fr",
            }
            if city is not None:
                profile["city_id"] = city.pk
                profile["timezone"] = city.timezone
            user, _ = accounts.create_account(
                email=demo_email(demo.slug),
                password=DEMO_PASSWORD,
                profile=profile,
                consents=ALL_CONSENTS,
                invite_code=None,
                device={"name": "Démo", "platform": "android", "fingerprint": f"demo-{demo.slug}"},
                meta=DEMO_META,
            )
            if demo.verified:
                user.email_verified_at = timezone.now()
                user.save(update_fields=["email_verified_at", "updated_at"])
            if demo.situation == "suspended":
                accounts.suspend_user(user=user, actor=None, reason="Compte de démonstration suspendu")
            users[demo.slug] = user
        return users

    def seed_staff(self) -> None:
        self.stdout.write("Staff de démo (mot de passe commun, TOTP ci-dessous) :")
        for slug, role in STAFF:
            user = User.objects.create_user(
                email=demo_email(f"staff.{slug}"),
                password=DEMO_PASSWORD,
                is_staff=True,
                email_verified_at=timezone.now(),
            )
            StaffRole.objects.create(user=user, role=role)
            secret, _, _ = mfa.enroll(user, secret=demo_totp_secret(slug, self.seed))
            self.stdout.write(f"  {user.email:<36} {role:<11} TOTP {secret}")
