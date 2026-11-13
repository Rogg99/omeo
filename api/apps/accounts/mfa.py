"""
Double authentification du staff : TOTP (pyotp, secret chiffré) et codes de secours hachés (usage unique).

Le `mfa_token` renvoyé par `/auth/login` est un jeton signé, valable 5 min, qui ne donne accès à rien d'autre
que `/auth/mfa/verify`.
"""

from __future__ import annotations

import secrets
from typing import Final

import pyotp
from django.contrib.auth.hashers import check_password, make_password
from django.core import signing
from django.db import transaction
from django.utils import timezone

from apps.accounts.models import RecoveryCode, TOTPDevice, User
from apps.core import crypto
from apps.core.errors import InvalidCredentials

ISSUER: Final = "Omeo Admin"
MFA_TOKEN_SALT: Final = "omeo.mfa"
MFA_TOKEN_MAX_AGE_S: Final = 300
RECOVERY_CODE_COUNT: Final = 10
VALID_WINDOW: Final = 1  # ±30 s de dérive d'horloge


def issue_mfa_token(user: User) -> str:
    return signing.dumps({"uid": str(user.pk)}, salt=MFA_TOKEN_SALT)


def user_from_mfa_token(token: str) -> User:
    try:
        data = signing.loads(token, salt=MFA_TOKEN_SALT, max_age=MFA_TOKEN_MAX_AGE_S)
    except signing.BadSignature:
        raise InvalidCredentials() from None
    user = User.objects.filter(pk=data.get("uid"), is_staff=True).first()
    if user is None:
        raise InvalidCredentials()
    return user


def new_secret() -> str:
    return pyotp.random_base32()


def provisioning_uri(secret: str, email: str) -> str:
    return pyotp.TOTP(secret).provisioning_uri(name=email, issuer_name=ISSUER)


@transaction.atomic
def enroll(user: User, *, secret: str | None = None) -> tuple[str, str, list[str]]:
    """Crée (ou remplace) le TOTP et les codes de secours. Renvoie secret, URI otpauth et codes en clair (une fois).

    `secret` n'est fourni que par `seed_demo` (TOTP de démo affiché) ; sinon il est tiré au hasard.
    """
    secret = secret or new_secret()
    TOTPDevice.objects.update_or_create(
        user=user,
        defaults={"secret_encrypted": crypto.encrypt(secret), "confirmed_at": None, "last_used_step": 0},
    )
    codes = regenerate_recovery_codes(user)
    return secret, provisioning_uri(secret, user.email), codes


def _recovery_code() -> str:
    """Format `xxxxx-xxxxx` (11 caractères, compatible avec le motif du contrat)."""
    alphabet = "abcdefghjkmnpqrstuvwxyz23456789"
    raw = "".join(secrets.choice(alphabet) for _ in range(10))
    return f"{raw[:5]}-{raw[5:]}"


def regenerate_recovery_codes(user: User) -> list[str]:
    RecoveryCode.objects.filter(user=user).delete()
    codes = [_recovery_code() for _ in range(RECOVERY_CODE_COUNT)]
    RecoveryCode.objects.bulk_create(RecoveryCode(user=user, code_hash=make_password(code)) for code in codes)
    return codes


def _verify_totp(device: TOTPDevice, code: str) -> bool:
    totp = pyotp.TOTP(crypto.decrypt(device.secret_encrypted))
    now = timezone.now()
    for offset in range(-VALID_WINDOW, VALID_WINDOW + 1):
        step = totp.timecode(now) + offset
        if step <= device.last_used_step:
            continue  # un code déjà utilisé ne peut pas être rejoué
        if secrets.compare_digest(totp.generate_otp(step), code):
            TOTPDevice.objects.filter(pk=device.pk).update(
                last_used_step=step, confirmed_at=device.confirmed_at or now
            )
            return True
    return False


def _use_recovery_code(user: User, code: str) -> bool:
    for recovery in RecoveryCode.objects.select_for_update().filter(user=user, used_at__isnull=True):
        if check_password(code, recovery.code_hash):
            recovery.used_at = timezone.now()
            recovery.save(update_fields=["used_at", "updated_at"])
            return True
    return False


@transaction.atomic
def verify_code(user: User, code: str) -> None:
    device = TOTPDevice.objects.select_for_update().filter(user=user).first()
    if device is None:
        raise InvalidCredentials()
    code = code.strip()
    ok = _verify_totp(device, code) if code.isdigit() and len(code) == 6 else _use_recovery_code(user, code)
    if not ok:
        raise InvalidCredentials()
