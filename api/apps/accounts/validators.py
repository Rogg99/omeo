"""Règle de mot de passe : au moins 10 caractères, une minuscule, une majuscule, un chiffre et un caractère spécial."""

from __future__ import annotations

import re
from typing import Any, Final

from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _

_RULES: Final[tuple[tuple[str, str, str], ...]] = (
    (r"[a-z]", "password_no_lower", "une minuscule"),
    (r"[A-Z]", "password_no_upper", "une majuscule"),
    (r"\d", "password_no_digit", "un chiffre"),
    (r"[^A-Za-z0-9]", "password_no_symbol", "un caractère spécial"),
)


class PasswordComplexityValidator:
    def validate(self, password: str, user: Any = None) -> None:
        errors = [
            ValidationError(_("Le mot de passe doit contenir %(rule)s.") % {"rule": _(label)}, code=code)
            for pattern, code, label in _RULES
            if not re.search(pattern, password)
        ]
        if errors:
            raise ValidationError(errors)

    def get_help_text(self) -> str:
        return _("Au moins 10 caractères, avec une minuscule, une majuscule, un chiffre et un caractère spécial.")
