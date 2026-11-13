"""
Écritures du compte : inscription, connexion (mot de passe, Google, Apple, TOTP), sessions, mots de passe, email,
consentements et code d'invitation. Toutes transactionnelles ; arguments nommés.
"""

from __future__ import annotations

import secrets
import string
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Any, Final, Literal

from django.contrib.auth.hashers import check_password, make_password
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.accounts import emails, mfa, one_time_tokens, social, tokens
from apps.accounts.models import (
    NON_WITHDRAWABLE_CONSENTS,
    REQUIRED_CONSENTS,
    City,
    Consent,
    DeviceFingerprint,
    LegalDocument,
    OneTimeTokenPurpose,
    Profile,
    ReferralCode,
    Session,
    SocialAccount,
    User,
)
from apps.billing import services as billing
from apps.billing.selectors import active_store_channel
from apps.core import audit, events, settings_store
from apps.core.audit import RequestMeta
from apps.core.errors import (
    Conflict,
    InvalidCredentials,
    MfaRequired,
    NotFound,
    ValidationFailed,
    field_errors,
)
from apps.core.localtime import DEFAULT_TZ, is_valid_timezone
from apps.core.permissions import STEP_UP_WINDOW
from apps.meals.services import consume_upload
from apps.nutrition import services as nutrition
from apps.nutrition.calculations import age_on

InviteStatus = Literal["none", "valid", "invalid"]
REFERRAL_ALPHABET: Final = string.ascii_uppercase.replace("O", "").replace("I", "") + "23456789"
REFERRAL_CODE_LENGTH: Final = 6
# Empreinte factice : un email inconnu coûte autant qu'un vrai (pas d'énumération par le temps de réponse).
_DUMMY_HASH: Final = make_password("timing-equalizer")


@dataclass(frozen=True, slots=True)
class AuthOutcome:
    user: User
    session: Session
    tokens: tokens.TokenPair
    created: bool
    invite_code_status: InviteStatus | None = None


# ───────────────────────── Validation ─────────────────────────


def check_password_strength(password: str, *, user: User | None = None, field: str = "password") -> None:
    try:
        validate_password(password, user=user)
    except DjangoValidationError as exc:
        raise ValidationFailed(
            errors={field: [{"code": e.code or "invalid", "message": " ".join(e.messages)} for e in exc.error_list]}
        ) from None


def _check_age(birth_date: date) -> None:
    min_age = int(settings_store.get("app.min_age", 16))
    if age_on(birth_date, timezone.localdate()) < min_age:
        raise ValidationFailed(
            errors=field_errors({"profile.birth_date": [f"min_age:{min_age}"]}, code="too_young"),
            meta={"min_age": min_age},
        )


def _current_document(kind: str) -> LegalDocument | None:
    return (
        LegalDocument.objects.filter(kind=kind, published_at__isnull=False).order_by("-version").first()
    )


def _validate_consents(consents: list[dict[str, Any]]) -> None:
    granted = {c["kind"] for c in consents if c.get("granted")}
    missing = [kind for kind in REQUIRED_CONSENTS if kind not in granted]
    if missing:
        raise ValidationFailed(
            errors={"consents": [{"code": "consent_required", "message": kind} for kind in missing]},
            meta={"documents": missing},
        )


def record_consents(*, user: User, consents: list[dict[str, Any]], meta: RequestMeta) -> None:
    rows = []
    for consent in consents:
        document = _current_document(consent["kind"]) if consent["kind"] in ("terms", "privacy") else None
        rows.append(
            Consent(
                user=user,
                kind=consent["kind"],
                granted=bool(consent["granted"]),
                document=document,
                ip=meta.ip,
                user_agent=meta.user_agent[:255],
            )
        )
    Consent.objects.bulk_create(rows)


# ───────────────────────── Parrainage ─────────────────────────


def _referral_code_owner(code: str | None) -> ReferralCode | None:
    if not code:
        return None
    return (
        ReferralCode.objects.select_related("user", "user__profile")
        .filter(code=code.strip().upper(), user__is_active=True)
        .first()
    )


def check_invite_code(*, code: str) -> dict[str, Any]:
    owner = _referral_code_owner(code)
    if owner is None:
        return {"valid": False, "referrer_first_name": None, "trial_days": billing.trial_days(with_invite=False)}
    profile = getattr(owner.user, "profile", None)
    return {
        "valid": True,
        "referrer_first_name": profile.first_name if profile else None,
        "trial_days": billing.trial_days(with_invite=True),
    }


def _new_referral_code() -> str:
    return "".join(secrets.choice(REFERRAL_ALPHABET) for _ in range(REFERRAL_CODE_LENGTH))


def ensure_referral_code(user: User) -> ReferralCode:
    existing = ReferralCode.objects.filter(user=user).first()
    if existing:
        return existing
    for _ in range(10):
        try:
            with transaction.atomic():
                return ReferralCode.objects.create(user=user, code=_new_referral_code())
        except IntegrityError:
            continue
    raise RuntimeError("Could not allocate a referral code")


def _record_fingerprint(user: User, device: dict[str, Any] | None) -> str | None:
    fingerprint = (device or {}).get("fingerprint")
    if not fingerprint:
        return None
    DeviceFingerprint.objects.get_or_create(user=user, hash=str(fingerprint)[:128])
    return str(fingerprint)


# ───────────────────────── Inscription ─────────────────────────


def _resolve_city(profile_data: dict[str, Any]) -> tuple[City | None, str]:
    city_id = profile_data.get("city_id")
    if not city_id:
        return None, ""
    city = City.objects.filter(pk=city_id).first()
    if city is None:
        raise ValidationFailed(errors=field_errors({"profile.city_id": ["unknown city"]}, code="not_found"))
    return city, city.country


def _create_profile(user: User, data: dict[str, Any]) -> Profile:
    city, country = _resolve_city(data)
    tz = data.get("timezone") or (city.timezone if city else DEFAULT_TZ)
    if not is_valid_timezone(tz):
        tz = city.timezone if city else DEFAULT_TZ
    return Profile.objects.create(
        user=user,
        first_name=data["first_name"].strip(),
        last_name=data["last_name"].strip(),
        birth_date=data["birth_date"],
        sex=data["sex"],
        city=city,
        city_label=(data.get("city_label") or "").strip(),
        country=country,
        timezone=tz,
        height_cm=Decimal(str(data["height_cm"])),
        current_weight_kg=Decimal(str(data["weight_kg"])),
        target_weight_kg=Decimal(str(data["target_weight_kg"])),
        goals=list(dict.fromkeys(data["goals"])),
    )


def _bootstrap_account(
    *,
    user: User,
    profile_data: dict[str, Any],
    consents: list[dict[str, Any]],
    invite_code: str | None,
    device: dict[str, Any] | None,
    meta: RequestMeta,
) -> InviteStatus:
    _check_age(profile_data["birth_date"])
    _validate_consents(consents)
    _create_profile(user, profile_data)
    record_consents(user=user, consents=consents, meta=meta)
    owner = _referral_code_owner(invite_code)
    status: InviteStatus = "none" if not invite_code else ("valid" if owner and owner.user_id != user.pk else "invalid")
    billing.start_trial(user=user, with_invite=status == "valid")
    nutrition.recompute_targets(user=user)
    ensure_referral_code(user)
    fingerprint = _record_fingerprint(user, device)
    events.publish(
        events.UserRegistered(
            user_id=user.pk, invite_code=invite_code if status == "valid" else None, device_fingerprint=fingerprint
        )
    )
    return status


def _normalize_email(email: str) -> str:
    return email.strip().lower()


@transaction.atomic
def create_account(
    *,
    email: str,
    password: str,
    profile: dict[str, Any],
    consents: list[dict[str, Any]],
    invite_code: str | None,
    device: dict[str, Any] | None,
    meta: RequestMeta,
) -> tuple[User, InviteStatus]:
    """Compte, profil, consentements, essai, objectifs et code de parrainage. Sans session ni email."""
    email = _normalize_email(email)
    if User.objects.filter(email__iexact=email).exists():
        raise Conflict(code="email_taken", detail="email already registered")
    candidate = User(email=email, locale=profile.get("locale") or "fr")
    check_password_strength(password, user=candidate)
    try:
        with transaction.atomic():
            user = User.objects.create_user(email=email, password=password, locale=candidate.locale)
    except IntegrityError:
        raise Conflict(code="email_taken", detail="email already registered") from None
    status = _bootstrap_account(
        user=user, profile_data=profile, consents=consents, invite_code=invite_code, device=device, meta=meta
    )
    return user, status


@transaction.atomic
def register(
    *,
    email: str,
    password: str,
    profile: dict[str, Any],
    consents: list[dict[str, Any]],
    invite_code: str | None,
    device: dict[str, Any] | None,
    meta: RequestMeta,
) -> AuthOutcome:
    user, status = create_account(
        email=email,
        password=password,
        profile=profile,
        consents=consents,
        invite_code=invite_code,
        device=device,
        meta=meta,
    )
    send_verification_email(user=user)
    session, pair = tokens.open_session(user=user, device=device, ip=meta.ip)
    return AuthOutcome(user=user, session=session, tokens=pair, created=True, invite_code_status=status)


@transaction.atomic
def suspend_user(*, user: User, actor: User | None, reason: str, request: Any = None) -> User:
    """Suspension : refus partout (403 account_suspended) et révocation immédiate de toutes les sessions."""
    before = {"is_active": user.is_active}
    user.is_active = False
    user.suspended_at = timezone.now()
    user.save(update_fields=["is_active", "suspended_at", "updated_at"])
    tokens.revoke_all(user, reason="suspended")
    audit.record(
        actor=actor,
        action="user.suspend",
        target_type="user",
        target_id=user.pk,
        before=before,
        after={"is_active": False},
        reason=reason,
        request=request,
    )
    events.publish(events.AccountSuspended(user_id=user.pk))
    return user


# ───────────────────────── Connexion ─────────────────────────


def login(*, email: str, password: str, device: dict[str, Any] | None, meta: RequestMeta) -> AuthOutcome:
    user = User.objects.filter(email__iexact=_normalize_email(email)).first()
    if user is None or not user.has_usable_password():
        check_password(password, _DUMMY_HASH)
        raise InvalidCredentials()
    if not user.check_password(password):
        raise InvalidCredentials()
    if not user.is_active:
        raise tokens.suspended_error()
    if user.is_staff:
        raise MfaRequired(meta={"mfa_token": mfa.issue_mfa_token(user)})
    session, pair = tokens.open_session(user=user, device=device, ip=meta.ip)
    return AuthOutcome(user=user, session=session, tokens=pair, created=False)


@transaction.atomic
def verify_mfa(*, mfa_token: str, code: str, device: dict[str, Any] | None, meta: RequestMeta) -> AuthOutcome:
    user = mfa.user_from_mfa_token(mfa_token)
    if not user.is_active:
        raise tokens.suspended_error()
    mfa.verify_code(user, code)
    session, pair = tokens.open_session(user=user, device=device, ip=meta.ip, mfa_verified=True)
    return AuthOutcome(user=user, session=session, tokens=pair, created=False)


@transaction.atomic
def step_up(*, session: Session, code: str) -> datetime:
    """Revalide le TOTP de la session ; renvoie la fin de validité du step-up."""
    mfa.verify_code(session.user, code)
    now = timezone.now()
    Session.objects.filter(pk=session.pk).update(mfa_verified_at=now)
    session.mfa_verified_at = now
    return now + STEP_UP_WINDOW


@transaction.atomic
def social_auth(
    *,
    provider: str,
    id_token: str,
    nonce: str | None,
    invite_code: str | None,
    profile: dict[str, Any] | None,
    consents: list[dict[str, Any]] | None,
    device: dict[str, Any] | None,
    meta: RequestMeta,
) -> AuthOutcome:
    identity = social.verify(provider, id_token, nonce=nonce)
    link = SocialAccount.objects.select_related("user").filter(provider=provider, subject=identity.subject).first()
    if link is not None:
        user = link.user
        if not user.is_active:
            raise tokens.suspended_error()
        if user.is_staff:
            raise InvalidCredentials()  # pas de connexion sociale pour le staff
        session, pair = tokens.open_session(user=user, device=device, ip=meta.ip)
        return AuthOutcome(user=user, session=session, tokens=pair, created=False)

    existing = User.objects.filter(email__iexact=identity.email).first() if identity.email else None
    if existing is not None:
        # Rattachement automatique seulement si le fournisseur garantit l'adresse : sinon prise de compte possible.
        if not identity.email_verified or existing.is_staff:
            raise Conflict(code="email_taken", detail="sign in with your password to link this account")
        if not existing.is_active:
            raise tokens.suspended_error()
        SocialAccount.objects.create(
            user=existing, provider=provider, subject=identity.subject, email=identity.email or ""
        )
        if existing.email_verified_at is None:
            existing.email_verified_at = timezone.now()
            existing.save(update_fields=["email_verified_at", "updated_at"])
        session, pair = tokens.open_session(user=existing, device=device, ip=meta.ip)
        return AuthOutcome(user=existing, session=session, tokens=pair, created=False)

    email = identity.email
    if not profile or not consents or not email:
        missing = {
            "profile": not profile,
            "consents": not consents,
            "id_token": not email,
        }
        raise ValidationFailed(
            errors=field_errors({k: ["required for sign-up"] for k, absent in missing.items() if absent}, code="required")
        )
    user = User.objects.create_user(
        email=email,
        password=None,
        locale=profile.get("locale") or "fr",
        email_verified_at=timezone.now() if identity.email_verified else None,
    )
    SocialAccount.objects.create(user=user, provider=provider, subject=identity.subject, email=email)
    status = _bootstrap_account(
        user=user, profile_data=profile, consents=consents, invite_code=invite_code, device=device, meta=meta
    )
    if not identity.email_verified:
        send_verification_email(user=user)
    session, pair = tokens.open_session(user=user, device=device, ip=meta.ip)
    return AuthOutcome(user=user, session=session, tokens=pair, created=True, invite_code_status=status)


def logout(*, session: Session, all_devices: bool) -> None:
    if all_devices:
        tokens.revoke_all(session.user, reason="logout_all")
    else:
        tokens.revoke(session, reason="logout")


# ───────────────────────── Mot de passe et email ─────────────────────────


def forgot_password(*, email: str) -> None:
    """Toujours silencieux : ne révèle jamais si l'adresse existe."""
    user = User.objects.filter(email__iexact=_normalize_email(email), is_active=True).first()
    if user is None:
        return
    raw = one_time_tokens.issue(user=user, purpose=OneTimeTokenPurpose.PASSWORD_RESET)
    transaction.on_commit(lambda: emails.send(user=user, kind="password_reset", token=raw))


@transaction.atomic
def reset_password(*, token: str, password: str) -> None:
    consumed = one_time_tokens.consume(raw=token, purpose=OneTimeTokenPurpose.PASSWORD_RESET)
    user = consumed.user
    check_password_strength(password, user=user)
    user.set_password(password)
    user.save(update_fields=["password", "updated_at"])
    tokens.revoke_all(user, reason="password_reset")


@transaction.atomic
def change_password(*, user: User, current_password: str | None, new_password: str, session: Session) -> None:
    if user.has_usable_password() and not user.check_password(current_password or ""):
        raise ValidationFailed(errors=field_errors({"current_password": ["wrong password"]}, code="invalid"))
    check_password_strength(new_password, user=user, field="new_password")
    user.set_password(new_password)
    user.save(update_fields=["password", "updated_at"])
    tokens.revoke_all(user, reason="password_change", except_session=session)


def send_verification_email(*, user: User) -> None:
    if user.email_verified_at is not None:
        return
    raw = one_time_tokens.issue(user=user, purpose=OneTimeTokenPurpose.EMAIL_VERIFY)
    transaction.on_commit(lambda: emails.send(user=user, kind="verify_email", token=raw))


@transaction.atomic
def verify_email(*, token: str) -> User:
    """Vérifie l'email du compte, ou confirme un changement d'adresse (`email_change`)."""
    try:
        consumed = one_time_tokens.consume(raw=token, purpose=OneTimeTokenPurpose.EMAIL_VERIFY)
        user = consumed.user
    except ValidationFailed:
        consumed = one_time_tokens.consume(raw=token, purpose=OneTimeTokenPurpose.EMAIL_CHANGE)
        user = consumed.user
        new_email = str(consumed.payload["new_email"])
        if User.objects.filter(email__iexact=new_email).exclude(pk=user.pk).exists():
            raise Conflict(code="email_taken", detail="email already registered")
        user.email = new_email
    first_verification = user.email_verified_at is None
    user.email_verified_at = timezone.now()
    user.save(update_fields=["email", "email_verified_at", "updated_at"])
    if first_verification:
        events.publish(events.EmailVerified(user_id=user.pk))
    return user


@transaction.atomic
def request_email_change(*, user: User, new_email: str, password: str | None) -> None:
    new_email = _normalize_email(new_email)
    if user.has_usable_password() and not user.check_password(password or ""):
        raise ValidationFailed(errors=field_errors({"password": ["wrong password"]}, code="invalid"))
    if User.objects.filter(email__iexact=new_email).exists():
        raise Conflict(code="email_taken", detail="email already registered")
    raw = one_time_tokens.issue(
        user=user, purpose=OneTimeTokenPurpose.EMAIL_CHANGE, payload={"new_email": new_email}
    )
    transaction.on_commit(lambda: emails.send(user=user, kind="email_change", token=raw, to=new_email))


# ───────────────────────── Profil ─────────────────────────

_TARGET_FIELDS: Final = frozenset({"birth_date", "sex", "height_cm", "target_weight_kg", "goals"})
_PROFILE_FIELDS: Final = frozenset(
    {
        "first_name",
        "last_name",
        "birth_date",
        "sex",
        "city_label",
        "height_cm",
        "target_weight_kg",
        "goals",
        "activity_adjustment",
        "theme",
        "unit_weight",
        "unit_height",
        "unit_volume",
    }
)


@transaction.atomic
def update_profile(*, user: User, data: dict[str, Any]) -> User:
    profile = Profile.objects.select_for_update().get(user=user)
    changed: list[str] = []
    if "birth_date" in data:
        _check_age(data["birth_date"])
    if "city_id" in data:
        if data["city_id"] is None:
            profile.city, profile.country = None, ""
        else:
            city, country = _resolve_city({"city_id": data["city_id"]})
            profile.city, profile.country = city, country
        changed += ["city", "country"]
    for name in _PROFILE_FIELDS & data.keys():
        value = data[name]
        if name == "goals":
            value = list(dict.fromkeys(value))
        elif name == "city_label":
            value = (value or "").strip()
        elif name in ("first_name", "last_name"):
            value = value.strip()
        setattr(profile, name, value)
        changed.append(name)
    if changed:
        profile.save(update_fields=[*dict.fromkeys(changed), "updated_at"])
    if "locale" in data and data["locale"] != user.locale:
        user.locale = data["locale"]
        user.save(update_fields=["locale", "updated_at"])
        changed.append("locale")
    user.profile = profile
    if _TARGET_FIELDS & set(changed):
        nutrition.recompute_targets(user=user)
    if changed:
        events.publish(events.ProfileChanged(user_id=user.pk, fields=tuple(changed)))
    return user


@transaction.atomic
def set_avatar(*, user: User, upload_id: Any) -> Profile:
    upload = consume_upload(user=user, upload_id=upload_id, kind="avatar")
    profile = Profile.objects.select_for_update().get(user=user)
    profile.avatar = upload
    profile.save(update_fields=["avatar", "updated_at"])
    return profile


@transaction.atomic
def delete_avatar(*, user: User) -> None:
    Profile.objects.filter(user=user).update(avatar=None, updated_at=timezone.now())


# ───────────────────────── Consentements ─────────────────────────


@transaction.atomic
def update_consents(*, user: User, consents: list[dict[str, Any]], meta: RequestMeta) -> None:
    withdrawn = [c["kind"] for c in consents if not c["granted"] and c["kind"] in NON_WITHDRAWABLE_CONSENTS]
    if withdrawn:
        raise ValidationFailed(
            errors={"consents": [{"code": "not_withdrawable", "message": kind} for kind in withdrawn]}
        )
    record_consents(user=user, consents=consents, meta=meta)


# ───────────────────────── Sessions ─────────────────────────


def revoke_session(*, user: User, session_id: Any) -> None:
    session = Session.objects.filter(user=user, pk=session_id, revoked_at__isnull=True).first()
    if session is None:
        raise NotFound()
    tokens.revoke(session, reason="user_revoked")


# ───────────────────────── Suppression du compte ─────────────────────────

DELETION_DELAY_DAYS: Final = 30


@dataclass(frozen=True, slots=True)
class DeletionScheduled:
    scheduled_for: Any
    store_channel: str | None


@transaction.atomic
def schedule_deletion(*, user: User) -> DeletionScheduled:
    now = timezone.now()
    user = User.objects.select_for_update().get(pk=user.pk)
    if user.deletion_scheduled_at is None:
        user.deletion_requested_at = now
        user.deletion_scheduled_at = now + timedelta(days=DELETION_DELAY_DAYS)
        user.save(update_fields=["deletion_requested_at", "deletion_scheduled_at", "updated_at"])
    tokens.revoke_all(user, reason="deletion_requested")
    return DeletionScheduled(scheduled_for=user.deletion_scheduled_at, store_channel=active_store_channel(user))


def request_account_deletion(*, user: User, password: str | None) -> DeletionScheduled:
    if user.has_usable_password() and not user.check_password(password or ""):
        raise ValidationFailed(errors=field_errors({"password": ["wrong password"]}, code="invalid"))
    return schedule_deletion(user=user)


def request_deletion_by_email(*, email: str) -> None:
    """Formulaire public (exigé par Google Play) : toujours silencieux, lien de confirmation par email."""
    user = User.objects.filter(email__iexact=_normalize_email(email)).first()
    if user is None or user.deletion_scheduled_at is not None:
        return
    raw = one_time_tokens.issue(user=user, purpose=OneTimeTokenPurpose.ACCOUNT_DELETION)
    transaction.on_commit(lambda: emails.send(user=user, kind="account_deletion", token=raw))


@transaction.atomic
def confirm_deletion_by_email(*, token: str) -> None:
    consumed = one_time_tokens.consume(raw=token, purpose=OneTimeTokenPurpose.ACCOUNT_DELETION)
    schedule_deletion(user=consumed.user)
