"""
`manage.py init_staff --domain my-omeo.app [--email role=adresse …] [--dry-run]`

Initialise l'équipe d'administration : un compte par rôle (superadmin, content, support, finance, moderation).

- Adresse par défaut : `<rôle>@<domaine>` (`--email support=awa@my-omeo.app` pour la remplacer).
- Idempotente : un rôle déjà tenu par un compte n'est pas recréé, une adresse déjà prise est refusée.
- Mot de passe aléatoire fort et double authentification enrôlée : identifiants affichés UNE SEULE FOIS, jamais
  écrits sur disque ni passés en variable d'environnement. Les transmettre par un canal sûr, chaque personne
  confirme ensuite son TOTP au premier login puis change son mot de passe.
- L'action est inscrite au journal d'audit avec l'acteur `system`.
"""

from __future__ import annotations

import secrets
import string
from dataclasses import dataclass
from typing import Any, Final

from django.core.management.base import BaseCommand, CommandError, CommandParser
from django.db import transaction
from django.utils import timezone

from apps.accounts import mfa
from apps.accounts.models import Role, StaffRole, User
from apps.accounts.services import check_password_strength
from apps.core import audit
from apps.core.errors import ValidationFailed

PASSWORD_LENGTH: Final = 24
PASSWORD_ALPHABET: Final = string.ascii_letters + string.digits + "-_.!@#%+="


@dataclass(frozen=True, slots=True)
class Credentials:
    role: str
    email: str
    password: str
    totp_secret: str
    totp_uri: str
    recovery_codes: list[str]


def generate_password() -> str:
    """Mot de passe aléatoire contenant au moins une minuscule, une majuscule, un chiffre et un symbole."""
    while True:
        password = "".join(secrets.choice(PASSWORD_ALPHABET) for _ in range(PASSWORD_LENGTH))
        if (
            any(c.islower() for c in password)
            and any(c.isupper() for c in password)
            and any(c.isdigit() for c in password)
            and any(not c.isalnum() for c in password)
        ):
            return password


def parse_overrides(values: list[str]) -> dict[str, str]:
    overrides: dict[str, str] = {}
    for value in values:
        role, sep, email = value.partition("=")
        if not sep or role not in Role.values or "@" not in email:
            raise CommandError(f"--email attend rôle=adresse avec un rôle parmi {', '.join(Role.values)} : {value!r}")
        overrides[role] = email.strip().lower()
    return overrides


class Command(BaseCommand):
    help = "Crée un compte d'administration par rôle, avec double authentification."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument("--domain", required=True, help="Domaine des adresses par défaut (<rôle>@<domaine>).")
        parser.add_argument("--email", action="append", default=[], metavar="ROLE=ADRESSE")
        parser.add_argument("--dry-run", action="store_true", help="Affiche ce qui serait créé, sans rien écrire.")

    def handle(self, *args: Any, **options: Any) -> None:
        domain = str(options["domain"]).strip().lower().lstrip("@")
        if not domain or "." not in domain:
            raise CommandError("Domaine invalide.")
        overrides = parse_overrides(options["email"])
        plan = self._plan(domain, overrides)
        if not plan:
            self.stdout.write(self.style.SUCCESS("Chaque rôle a déjà son compte, rien à faire."))
            return
        if options["dry_run"]:
            for role, email in plan:
                self.stdout.write(f"  créerait {email:<36} {role}")
            return
        with transaction.atomic():
            created = [self._create(role, email) for role, email in plan]
        self._print(created)

    def _plan(self, domain: str, overrides: dict[str, str]) -> list[tuple[str, str]]:
        held = set(StaffRole.objects.values_list("role", flat=True))
        plan: list[tuple[str, str]] = []
        for role in Role.values:
            if role in held:
                self.stdout.write(f"  {role:<11} déjà attribué, ignoré")
                continue
            email = overrides.get(role, f"{role}@{domain}")
            if User.objects.filter(email__iexact=email).exists():
                raise CommandError(f"Un compte existe déjà avec {email} : choisis une autre adresse via --email.")
            plan.append((role, email))
        emails = [email for _, email in plan]
        if len(set(emails)) != len(emails):
            raise CommandError("Une même adresse ne peut tenir qu'un rôle ici : ajoute les rôles depuis l'admin.")
        return plan

    def _create(self, role: str, email: str) -> Credentials:
        password = generate_password()
        try:
            check_password_strength(password, user=User(email=email))
        except ValidationFailed as exc:  # pragma: no cover - mot de passe aléatoire de 24 caractères
            raise CommandError(f"Mot de passe généré refusé pour {email}.") from exc
        user = User.objects.create_user(email=email, password=password, is_staff=True, email_verified_at=timezone.now())
        StaffRole.objects.create(user=user, role=role)
        secret, uri, codes = mfa.enroll(user)
        self._audit(user, role)
        return Credentials(role, email, password, secret, uri, codes)

    @staticmethod
    def _audit(user: User, role: str) -> None:
        audit.record(
            actor=None,
            action="staff.initialized",
            target_type="user",
            target_id=user.pk,
            after={"role": role},
            reason="manage.py init_staff",
        )

    def _print(self, created: list[Credentials]) -> None:
        self.stdout.write(self.style.WARNING("Identifiants affichés une seule fois : transmets-les par un canal sûr."))
        for item in created:
            self.stdout.write("")
            self.stdout.write(self.style.MIGRATE_HEADING(f"[{item.role}] {item.email}"))
            self.stdout.write(f"  Mot de passe     : {item.password}")
            self.stdout.write(f"  Clé TOTP         : {item.totp_secret}")
            self.stdout.write(f"  URI TOTP         : {item.totp_uri}")
            self.stdout.write(f"  Codes de secours : {' '.join(item.recovery_codes)}")
        self.stdout.write("")
        self.stdout.write(self.style.SUCCESS(f"{len(created)} compte(s) d'administration créé(s)."))
