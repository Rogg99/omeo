"""
`manage.py seed_demo [--reset] [--seed 42]` : données de démo identiques aux maquettes (docs/technique/seeders.md).

- Interdite en production.
- Déterministe : graine fixe, dates relatives à aujourd'hui.
- Passe par les VRAIS services (création de compte, objectifs, suspension…), jamais par des insertions directes.
- `--reset` ne supprime que les comptes `@demo.my-omeo.app` (et, plus tard, les contenus étiquetés `demo`).

Chaque module ajoute sa section (repas, eau, activité, challenges, paiements…) à `SECTIONS`.
"""

from __future__ import annotations

import base64
import hashlib
import random
from dataclasses import dataclass
from datetime import date, timedelta
from decimal import Decimal
from pathlib import Path
from typing import Any, Final

import yaml
from django.conf import settings
from django.core.management import call_command
from django.core.management.base import BaseCommand, CommandError, CommandParser
from django.db import transaction
from django.utils import timezone

from apps.accounts import mfa
from apps.accounts import services as accounts
from apps.accounts.models import City, ReferralCode, Role, StaffRole, User
from apps.activity import services as activity
from apps.billing import services as billing_services
from apps.billing import subscriptions as billing_subscriptions
from apps.billing.models import Payment, Plan, Trial
from apps.billing.providers.base import VerifiedSubscription
from apps.billing.services import invalidate_entitlement
from apps.content.models import FaqItem, Plant, PreventionTip, Recipe
from apps.core.approvals import ApprovalService
from apps.core.audit import RequestMeta
from apps.core.localtime import day_bounds, local_today
from apps.core.models import ApprovalKind, ApprovalRequest, ContentStatus
from apps.foodscan.schemas import ScanOutput
from apps.foodscan.services import ScanResult
from apps.meals import services as meals_service
from apps.notifications.models import Campaign
from apps.notifications.services import notify
from apps.nutrition import services as nutrition
from apps.nutrition.calculations import NUTRIENT_KEYS
from apps.nutrition.models import Dish, DishComponent, Food
from apps.programs import services as programs_service
from apps.programs.models import (
    Challenge,
    ChallengeParticipation,
    Enrollment,
    Program,
    ProgramDay,
    ProgramTask,
    Rule,
)
from apps.support import services as support_services
from apps.support.models import Ticket

DEMO_DOMAIN: Final = "demo.my-omeo.app"
DEMO_SEED_DIR: Final = Path(settings.BASE_DIR) / "seeds" / "demo"
HISTORY_DAYS: Final = 60
SYNC_DAYS: Final = 30  # la synchronisation santé n'accepte que les 30 derniers jours
STREAK_DAYS: Final = 12  # série en cours d'Awa dans les maquettes
TODAY_STEPS: Final[dict[str, int]] = {"awa": 6420}  # valeurs des maquettes (accueil d'Awa)
MealPlan = list[tuple[str, str | None, float, list[tuple[str, int]]]]
# Journées types : (type de repas, plat du catalogue ou None, portions, aliments si pas de plat)
DAY_PATTERNS: Final[dict[str, MealPlan]] = {
    "complete": [
        ("breakfast", None, 1, [("pain", 80), ("oeuf", 100), ("the_sucre", 150)]),
        ("lunch", "Attiéké poisson braisé", 1, []),
        ("snack", None, 1, [("mangue", 150)]),
        ("dinner", "Riz au niébé", 1, []),
    ],
    "salty": [
        ("breakfast", None, 1, [("mil", 300)]),
        ("lunch", "Thiéboudienne", 1.25, []),
        ("dinner", "Mafé", 1, []),
    ],
    "partial": [("lunch", "Ndolé", 1, [])],
    "heavy": [
        ("breakfast", None, 1, [("pain", 120), ("arachide_pate", 30)]),
        ("lunch", "Foutou sauce graine", 1.5, []),
        ("snack", None, 1, [("plantain_frit", 200)]),
        ("dinner", "Poulet yassa", 1.25, []),
    ],
}
# Aujourd'hui pour Awa : petit-déjeuner et déjeuner (journée en cours, environ 1 450 kcal comme dans les maquettes)
AWA_TODAY: Final[MealPlan] = [
    ("breakfast", None, 1, [("mil", 250), ("banane", 120)]),
    ("lunch", "Ndolé", 1.3, []),
]
_REFEREE_PROFILE: Final[dict[str, Any]] = {
    "first_name": "Kofi",
    "last_name": "Filleul",
    "sex": "male",
    "height_cm": 176,
    "weight_kg": 74,
    "target_weight_kg": 72,
    "goals": ["eat_balanced"],
}
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
    DemoUser(
        "awa",
        "Awa",
        "Diallo",
        "female",
        30,
        "Yaoundé",
        175,
        78.4,
        74,
        ["lose_weight", "eat_balanced", "prevent_diabetes"],
        "trial",
    ),
    DemoUser(
        "moussa",
        "Moussa",
        "Koné",
        "male",
        34,
        "Abidjan",
        178,
        84.0,
        80,
        ["lose_weight", "prevent_hypertension"],
        "free",
    ),
    DemoUser("fatou", "Fatou", "Kane", "female", 27, "Dakar", 165, 61.0, 61, ["eat_balanced"], "plus_monthly"),
    DemoUser("koffi", "Koffi", "Mensah", "male", 29, "Lomé", 181, 72.0, 77, ["gain_muscle"], "plus_annual"),
    DemoUser(
        "aicha",
        "Aïcha",
        "Traoré",
        "female",
        41,
        "Bamako",
        162,
        70.5,
        65,
        ["lose_weight", "prevent_diabetes"],
        "quota_exhausted",
    ),
    DemoUser(
        "nouveau", "Nouveau", "Compte", "female", 24, "Cotonou", 168, 60.0, 58, ["eat_balanced"], "new", verified=False
    ),
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
            self.seed_catalog()
            self.seed_content()
            users = self.seed_accounts()
            self.seed_staff()
            self.seed_water(users)
            self.seed_activity(users)
            self.seed_programs(users)
            self.seed_billing(users)
            self.seed_meals(users)
            self.seed_engagement(users)
        self.stdout.write(self.style.SUCCESS(f"seed_demo : {len(users)} comptes et {len(STAFF)} membres du staff."))

    def reset(self) -> None:
        demo_users = User.objects.filter(email__endswith=f"@{DEMO_DOMAIN}")
        Campaign.objects.filter(created_by__in=demo_users).delete()
        ApprovalRequest.objects.filter(requested_by__in=demo_users).delete()
        Enrollment.objects.filter(user__email__endswith=f"@{DEMO_DOMAIN}").delete()
        ChallengeParticipation.objects.filter(user__email__endswith=f"@{DEMO_DOMAIN}").delete()
        Program.objects.filter(is_demo=True).delete()
        Challenge.objects.filter(is_demo=True).delete()
        Recipe.objects.filter(is_demo=True).delete()
        Plant.objects.filter(is_demo=True).delete()
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

    def seed_catalog(self) -> None:
        """Mini-catalogue publié (source `demo`), créé une fois puis conservé entre deux `--reset`."""
        foods: dict[str, Food] = {}
        for key, row in yaml.safe_load((DEMO_SEED_DIR / "foods.yaml").read_text(encoding="utf-8")).items():
            name_fr, name_en, category, *values, portion, aliases = row
            food = Food.objects.filter(source="demo", source_ref=key).first() or Food(source="demo", source_ref=key)
            food.name = {"fr": name_fr, "en": name_en}
            food.category = category
            food.aliases = list(aliases)
            food.default_portion_g = Decimal(str(portion))
            food.status = ContentStatus.PUBLISHED
            for field, value in zip(NUTRIENT_KEYS, values, strict=True):
                setattr(food, field, Decimal(str(value)))
            foods[key] = nutrition.save_food(food=food)
        for row in yaml.safe_load((DEMO_SEED_DIR / "dishes.yaml").read_text(encoding="utf-8")).values():
            if Dish.objects.filter(name__fr=row["name"]["fr"]).exists():
                continue
            components = row["components"]
            dish = Dish.objects.create(
                name=row["name"],
                aliases=row["aliases"],
                country=row["country"],
                standard_portion_g=Decimal(sum(components.values())),
                status=ContentStatus.PUBLISHED,
            )
            DishComponent.objects.bulk_create(
                DishComponent(dish=dish, food=foods[key], grams=Decimal(str(grams)))
                for key, grams in components.items()
            )
            nutrition.refresh_dish(dish=dish)

    def seed_content(self) -> None:
        """Contenus importés en brouillon (comme en production), puis publiés : en démo, tout est publié."""
        folder = DEMO_SEED_DIR / "content"
        call_command("import_content", str(folder), "--tag-demo", verbosity=0)
        Recipe.objects.filter(is_demo=True).update(status=ContentStatus.PUBLISHED)
        Plant.objects.filter(is_demo=True).update(status=ContentStatus.PUBLISHED)
        tip_codes = [row["code"] for row in yaml.safe_load((folder / "tips.yaml").read_text(encoding="utf-8"))]
        PreventionTip.objects.filter(code__in=tip_codes).update(status=ContentStatus.PUBLISHED)
        questions = [row["question"]["fr"] for row in yaml.safe_load((folder / "faq.yaml").read_text(encoding="utf-8"))]
        FaqItem.objects.filter(question__fr__in=questions).update(status=ContentStatus.PUBLISHED)

    def seed_water(self, users: dict[str, User]) -> None:
        """60 jours d'hydratation variée (comptes actifs), par `add_water` : la projection est recalculée."""
        for slug, user in users.items():
            if slug in ("nouveau", "suspendu"):
                continue
            today = local_today(user)
            for offset in range(HISTORY_DAYS, -1, -1):
                glasses = self.rng.choice((0, 3, 5, 6, 8, 10))
                if glasses:
                    nutrition.add_water(user=user, amount_ml=glasses * 250, day=today - timedelta(days=offset))

    def seed_activity(self, users: dict[str, User]) -> None:
        """
        Pesées hebdomadaires (en baisse ou stables), pas des 30 derniers jours via la synchronisation santé,
        et quelques activités manuelles plus anciennes. Tout passe par les services d'activity.
        """
        for slug, user in users.items():
            demo = next(d for d in DEMO_USERS if d.slug == slug)
            if demo.situation in ("new", "suspended"):
                continue
            today = local_today(user)
            losing = "lose_weight" in demo.goals
            start_weight = demo.weight_kg + (2.1 if losing else 0.0)
            weeks = HISTORY_DAYS // 7
            for week in range(weeks, -1, -1):
                progress = (weeks - week) / weeks
                weight = start_weight - (start_weight - demo.weight_kg) * progress
                activity.add_weight(
                    user=user,
                    weight_kg=Decimal(str(round(weight, 1))),
                    day=today - timedelta(days=week * 7),
                )
            sync_days = [
                {
                    "date": today - timedelta(days=offset),
                    "steps": TODAY_STEPS[slug]
                    if offset == 0 and slug in TODAY_STEPS
                    else self.rng.choice((2500, 4800, 6200, 8300, 9700, 12100)),
                    "active_kcal": self.rng.choice((120, 210, 340, 460)),
                }
                for offset in range(SYNC_DAYS - 1, -1, -1)
            ]
            activity.set_health_connection(
                user=user, source="health_connect", granted_types=["steps", "distance", "active_calories", "weight"]
            )
            activity.sync_health(user=user, source="health_connect", days=sync_days, workouts=[], weights=[])
            for offset in range(HISTORY_DAYS, SYNC_DAYS, 4):
                activity.create_activity(
                    user=user,
                    data={
                        "type": self.rng.choice(("walking", "running", "football", "dancing")),
                        "intensity": self.rng.choice(("light", "moderate", "vigorous")),
                        "duration_s": self.rng.choice((1200, 1800, 2700, 3600)),
                        "date": today - timedelta(days=offset),
                        "started_at": timezone.now() - timedelta(days=offset),
                    },
                )

    def seed_programs(self, users: dict[str, User]) -> None:
        """Programmes et challenges publiés ; Awa a un programme à mi-parcours et un challenge actif."""
        data = yaml.safe_load((DEMO_SEED_DIR / "programs.yaml").read_text(encoding="utf-8"))
        programs: list[Program] = []
        for row in data["programs"]:
            program = Program.objects.create(
                name=row["name"],
                description=row["description"],
                goal=row["goal"],
                weeks=row["weeks"],
                points=row["points"],
                status=ContentStatus.PUBLISHED,
                is_demo=True,
            )
            rules_by_task = [Rule.objects.create(**t["rule"]) if t.get("rule") else None for t in row["daily_tasks"]]
            for index in range(1, row["weeks"] * 7 + 1):
                day = ProgramDay.objects.create(program=program, day_index=index)
                for order, (task, rule) in enumerate(zip(row["daily_tasks"], rules_by_task, strict=True)):
                    ProgramTask.objects.create(day=day, label=task["label"], rule=rule, order=order)
            programs.append(program)
        challenges = [
            Challenge.objects.create(
                name=row["name"],
                description=row.get("description", {}),
                duration_days=row["duration_days"],
                rule=Rule.objects.create(**row["rule"]),
                status=ContentStatus.PUBLISHED,
                is_demo=True,
            )
            for row in data["challenges"]
        ]
        awa = users["awa"]
        enrollment = programs_service.enroll(user=awa, program_id=programs[0].pk, replace=False)
        # Situation des maquettes : programme commencé il y a 13 jours (jour 14 sur 28)
        Enrollment.objects.filter(pk=enrollment.pk).update(started_on=local_today(awa) - timedelta(days=13))
        programs_service.join_challenge(user=awa, challenge_id=challenges[0].pk)
        programs_service.join_challenge(user=users["fatou"], challenge_id=challenges[1].pk)

    def seed_billing(self, users: dict[str, User]) -> None:
        """Offres de chaque compte : Free (essai terminé), Plus store, Plus web, quota épuisé, paiements variés."""
        now = timezone.now()
        for slug in ("moussa", "aicha", "fatou", "koffi"):
            Trial.objects.filter(user=users[slug]).update(ends_at=now - timedelta(days=10))
            invalidate_entitlement(users[slug].pk)
        Plan.objects.filter(code="plus_monthly").update(web_price_id="price_demo_monthly")
        Plan.objects.filter(code="plus_annual").update(web_price_id="price_demo_annual")
        store = VerifiedSubscription(
            channel="google_play",
            external_id="demo-fatou-token",
            product_id="omeo_plus_monthly",
            status="active",
            period_start=now - timedelta(days=12),
            period_end=now + timedelta(days=18),
            auto_renew=True,
            event_at=now,
        )
        billing_subscriptions.apply_verified(user=users["fatou"], verified=store)
        web = VerifiedSubscription(
            channel="web",
            external_id="sub_demo_koffi",
            product_id="price_demo_annual",
            status="active",
            period_start=now - timedelta(days=40),
            period_end=now + timedelta(days=325),
            auto_renew=True,
            event_at=now,
            raw={"customer": "cus_demo_koffi"},
        )
        subscription = billing_subscriptions.apply_verified(user=users["koffi"], verified=web)
        for index, (status, amount, days_ago) in enumerate(
            (("succeeded", 4699, 40), ("failed", 449, 75), ("refunded", 449, 70))
        ):
            Payment.objects.create(
                user=users["koffi"],
                subscription=subscription,
                channel="web",
                amount_cents=amount,
                status=status,
                external_id=f"pi_demo_koffi_{index}",
                paid_at=now - timedelta(days=days_ago),
            )
        aicha = users["aicha"]
        limit = billing_services.quota_limit(user=aicha, feature="photo_analysis") or 0
        for _ in range(limit):
            billing_services.consume_quota(user=aicha, feature="photo_analysis")

    def _log(self, user: User, day: date, meals: MealPlan) -> None:
        """Enregistre une journée de repas par `create_meal` (heures locales réalistes, jamais dans le futur)."""
        hours = {"breakfast": 8, "lunch": 13, "snack": 16, "dinner": 20}
        foods = {f.source_ref: f for f in Food.objects.filter(source="demo")}
        dishes = {d.name.get("fr"): d for d in Dish.objects.filter(status=ContentStatus.PUBLISHED)}
        start, _end = day_bounds(user, day)
        for meal_type, dish_name, portions, items in meals:
            eaten_at = start + timedelta(hours=hours[meal_type], minutes=self.rng.randint(0, 40))
            if eaten_at > timezone.now():
                continue
            if dish_name:
                meals_service.create_meal(
                    user=user,
                    source="dish",
                    meal_type=meal_type,
                    day=day,
                    eaten_at=eaten_at,
                    dish_id=dishes[dish_name].pk,
                    portions=Decimal(str(portions)),
                )
            else:
                meals_service.create_meal(
                    user=user,
                    source="foods",
                    meal_type=meal_type,
                    day=day,
                    eaten_at=eaten_at,
                    items=[{"food_id": foods[key].pk, "grams": grams} for key, grams in items],
                )

    def seed_meals(self, users: dict[str, User]) -> None:
        """60 jours de repas variés (complets, vides, salés, excès), par les services : projection et points réels."""
        for slug, user in users.items():
            demo = next(d for d in DEMO_USERS if d.slug == slug)
            if demo.situation in ("new", "suspended"):
                continue
            today = local_today(user)
            for offset in range(HISTORY_DAYS, 0, -1):
                if slug == "awa" and offset <= STREAK_DAYS:
                    pattern = "complete"
                else:
                    pattern = self.rng.choices(
                        ["complete", "salty", "partial", "heavy", "empty"], weights=[45, 15, 15, 10, 15]
                    )[0]
                if pattern != "empty":
                    self._log(user, today - timedelta(days=offset), DAY_PATTERNS[pattern])
            self._log(user, today, AWA_TODAY if slug == "awa" else DAY_PATTERNS["partial"])

    def _seed_feedback(self, user: User) -> None:
        for rating, label, correction in (("up", "Ndolé", None), ("down", "Sauce gombo", "Eru")):
            created = meals_service.create_analysis(user=user, kind="text", text=f"{label} avec du manioc")
            meals_service.store_result(
                analysis_id=created.analysis.pk,
                result=ScanResult(
                    succeeded=True,
                    failure_reason=None,
                    output=ScanOutput.model_validate(
                        {"contains_food": True, "dish_label": label, "confidence": 0.72, "items": []}
                    ),
                    low_confidence=False,
                    model="demo",
                    prompt_version="meal-v1",
                ),
            )
            meals_service.submit_feedback(
                user=user,
                analysis_id=created.analysis.pk,
                rating=rating,
                reason="wrong_dish" if correction else None,
                corrected_dish_label=correction,
                comment="Ce n'est pas le bon plat" if correction else None,
            )

    def _seed_tickets(self, user: User) -> None:
        statuses = (("question", "new"), ("technical", "open"), ("billing", "waiting_user"), ("suggestion", "resolved"))
        for index, (category, status_value) in enumerate(statuses):
            ticket = support_services.create_ticket(
                user=user,
                category=category,
                subject=f"Demande de démonstration n°{index + 1}",
                message="Bonjour, j'ai une question sur l'application Omeo.",
                email=None,
                name="",
                attachment_ids=[],
                meta={"app_version": "1.0.0", "os": "android 15"},
                channel="app",
            )
            Ticket.objects.filter(pk=ticket.pk).update(status=status_value)

    def _seed_referrals(self, referrer: User) -> None:
        """Un filleul validé (email vérifié et premier repas), un autre en attente."""
        code = ReferralCode.objects.get(user=referrer).code
        for index in range(2):
            referee, _status = accounts.create_account(
                email=demo_email(f"filleul{index + 1}"),
                password=DEMO_PASSWORD,
                profile={**_REFEREE_PROFILE, "birth_date": birth_date_for(26, self.today, self.rng)},
                consents=ALL_CONSENTS,
                invite_code=code,
                device={"fingerprint": f"demo-referee-{index}"},
                meta=DEMO_META,
            )
            if index == 0:
                accounts.verify_email_directly(user=referee)
                self._log(referee, local_today(referee), DAY_PATTERNS["partial"])

    def _seed_staff_work(self) -> None:
        """Campagnes à chaque statut et une demande de publication en attente de relecture."""
        author = User.objects.get(email=demo_email("staff.content"))
        for status_value, offset in (("draft", None), ("scheduled", 2), ("sent", -3)):
            Campaign.objects.create(
                title={"fr": "Nouvelles recettes", "en": "New recipes"},
                body={"fr": "Découvre 3 recettes légères de la semaine.", "en": "Discover 3 light recipes this week."},
                segment={"locales": ["fr"]},
                scheduled_at=timezone.now() + timedelta(days=offset) if offset is not None else None,
                status=status_value,
                sent_count=120 if status_value == "sent" else 0,
                opened_count=41 if status_value == "sent" else 0,
                created_by=author,
            )
        recipe = Recipe.objects.filter(is_demo=True).first()
        if recipe is not None:
            ApprovalService.create(
                kind=ApprovalKind.CONTENT_PUBLISH,
                payload={"type": "recipes", "id": str(recipe.pk)},
                diff={"before": {"status": "review"}, "after": {"status": "published"}},
                target_type="recipes",
                target_id=str(recipe.pk),
                reason="Nouvelle recette à relire",
                requested_by=author,
            )

    def seed_engagement(self, users: dict[str, User]) -> None:
        """Avis IA, demandes de support, parrainages, travail du staff et notifications lues et non lues."""
        self._seed_feedback(users["awa"])
        self._seed_tickets(users["moussa"])
        self._seed_referrals(users["awa"])
        self._seed_staff_work()
        for index, title in enumerate(("Badge obtenu : premier repas", "Ton challenge Hydratation a commencé")):
            notification = notify(
                user=users["awa"], category="reward", title=title, body="Bravo, continue comme ça !", push=False
            )
            if notification is not None and index == 0:
                notification.read_at = timezone.now()
                notification.save(update_fields=["read_at"])

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
