"""
`manage.py create_superadmin --email …` : premier compte superadmin (interactif).

Demande le mot de passe (jamais en argument ni en variable d'environnement), puis affiche le QR de la double
authentification et les codes de secours, une seule fois.
"""

from __future__ import annotations

import getpass
import io
from typing import Any

import qrcode
from django.core.management.base import BaseCommand, CommandError, CommandParser
from django.db import transaction

from apps.accounts import mfa
from apps.accounts.models import Role, StaffRole, User
from apps.accounts.services import check_password_strength
from apps.core.errors import ValidationFailed


class Command(BaseCommand):
    help = "Crée un compte superadmin et sa double authentification."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument("--email", required=True)

    def handle(self, *args: Any, **options: Any) -> None:
        email = str(options["email"]).strip().lower()
        if User.objects.filter(email__iexact=email).exists():
            raise CommandError("Un compte existe déjà avec cet email.")
        password = getpass.getpass("Mot de passe : ")
        if password != getpass.getpass("Confirmation : "):
            raise CommandError("Les mots de passe ne correspondent pas.")
        try:
            check_password_strength(password, user=User(email=email))
        except ValidationFailed as exc:
            messages = [m["message"] for errors in exc.errors.values() for m in errors]
            raise CommandError("\n".join(messages)) from None

        with transaction.atomic():
            user = User.objects.create_user(email=email, password=password, is_staff=True)
            StaffRole.objects.create(user=user, role=Role.SUPERADMIN)
            secret, uri, codes = mfa.enroll(user)

        qr = qrcode.QRCode(border=1)
        qr.add_data(uri)
        buffer = io.StringIO()
        qr.print_ascii(out=buffer, invert=True)
        self.stdout.write(buffer.getvalue())
        self.stdout.write(f"Clé TOTP (saisie manuelle) : {secret}")
        self.stdout.write("Codes de secours (à conserver hors ligne, affichés une seule fois) :")
        for code in codes:
            self.stdout.write(f"  {code}")
        self.stdout.write(self.style.SUCCESS(f"Superadmin {email} créé."))
