"""Emails transactionnels du compte, rendus dans la langue de l'utilisateur et envoyés par Celery."""

from __future__ import annotations

from django.conf import settings
from django.utils import translation
from django.utils.translation import gettext as _

from apps.accounts.models import User
from apps.core.i18n import to_django_locale


def _link(path: str, token: str) -> str:
    return f"{settings.WEB_BASE_URL.rstrip('/')}/{path}?token={token}"


def _render(user: User, kind: str, token: str) -> tuple[str, str]:
    with translation.override(to_django_locale(user.locale)):
        if kind == "verify_email":
            return _("Confirme ton adresse email"), _(
                "Bienvenue sur Omeo ! Confirme ton adresse en ouvrant ce lien : %(link)s"
            ) % {"link": _link("verify-email", token)}
        if kind == "password_reset":
            return _("Réinitialise ton mot de passe"), _(
                "Pour choisir un nouveau mot de passe, ouvre ce lien (valable 1 heure) : %(link)s\n"
                "Si tu n'es pas à l'origine de cette demande, ignore ce message."
            ) % {"link": _link("reset-password", token)}
        if kind == "email_change":
            return _("Confirme ta nouvelle adresse email"), _(
                "Ouvre ce lien pour confirmer ta nouvelle adresse : %(link)s"
            ) % {"link": _link("verify-email", token)}
        if kind == "account_deletion":
            return _("Confirme la suppression de ton compte"), _(
                "Ouvre ce lien pour confirmer la suppression de ton compte Omeo : %(link)s\n"
                "Tes données seront supprimées définitivement 30 jours après la confirmation."
            ) % {"link": _link("account-deletion/confirm", token)}
    raise ValueError(f"Unknown email kind: {kind}")


def send(*, user: User, kind: str, token: str, to: str | None = None) -> None:
    from apps.accounts.tasks import send_account_email

    subject, body = _render(user, kind, token)
    send_account_email.delay(to=to or user.email, subject=subject, body=body)
