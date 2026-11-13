"""Entrées et sorties du compte et de l'authentification. Aucune logique métier ici."""

from __future__ import annotations

from typing import Any

from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

from apps.accounts.models import ConsentKind, Goal, Locale, Platform, Sex, Theme
from apps.core.i18n import resolve
from apps.core.storage import presign_download

INVITE_CODE_REGEX = r"^[A-Za-z0-9]{4,10}$"
MFA_CODE_REGEX = r"^[0-9A-Za-z-]{6,12}$"


# ───────────────────────── Entrées ─────────────────────────


class DeviceInfoSerializer(serializers.Serializer[Any]):
    name = serializers.CharField(max_length=80, required=False, allow_blank=True)
    platform = serializers.ChoiceField(choices=Platform.choices, required=False)
    app_version = serializers.CharField(max_length=20, required=False, allow_blank=True)
    fingerprint = serializers.CharField(max_length=128, required=False, allow_blank=True)


class OnboardingProfileSerializer(serializers.Serializer[Any]):
    first_name = serializers.CharField(min_length=1, max_length=40)
    last_name = serializers.CharField(min_length=1, max_length=40)
    birth_date = serializers.DateField()
    sex = serializers.ChoiceField(choices=Sex.choices)
    city_id = serializers.UUIDField(required=False)
    city_label = serializers.CharField(max_length=80, required=False, allow_blank=True)
    height_cm = serializers.DecimalField(max_digits=5, decimal_places=1, min_value=100, max_value=250)
    weight_kg = serializers.DecimalField(max_digits=5, decimal_places=2, min_value=30, max_value=300)
    target_weight_kg = serializers.DecimalField(max_digits=5, decimal_places=2, min_value=30, max_value=300)
    goals = serializers.ListField(child=serializers.ChoiceField(choices=Goal.choices), min_length=1, max_length=5)
    locale = serializers.ChoiceField(choices=Locale.choices, required=False)
    timezone = serializers.CharField(max_length=64, required=False)

    def validate_goals(self, value: list[str]) -> list[str]:
        if len(set(value)) != len(value):
            raise serializers.ValidationError("duplicate goals", code="unique")
        return value

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        full_name = f"{attrs['first_name'].strip()}{attrs['last_name'].strip()}"
        if not 2 <= len(full_name) <= 60:
            raise serializers.ValidationError({"first_name": "name length"}, code="invalid")
        return attrs


class ConsentInputSerializer(serializers.Serializer[Any]):
    kind = serializers.ChoiceField(choices=ConsentKind.choices)
    granted = serializers.BooleanField()
    version = serializers.IntegerField(required=False, min_value=1)


class RegisterSerializer(serializers.Serializer[Any]):
    email = serializers.EmailField(max_length=254)
    password = serializers.CharField(min_length=10, max_length=128, trim_whitespace=False)
    invite_code = serializers.RegexField(INVITE_CODE_REGEX, required=False)
    profile = OnboardingProfileSerializer()
    consents = ConsentInputSerializer(many=True, min_length=2)
    device = DeviceInfoSerializer(required=False)


class LoginSerializer(serializers.Serializer[Any]):
    email = serializers.EmailField(max_length=254)
    password = serializers.CharField(max_length=128, trim_whitespace=False)
    device = DeviceInfoSerializer(required=False)


class SocialAuthSerializer(serializers.Serializer[Any]):
    provider = serializers.ChoiceField(choices=[("google", "google"), ("apple", "apple")])
    id_token = serializers.CharField(max_length=8192)
    nonce = serializers.CharField(max_length=255, required=False)
    invite_code = serializers.RegexField(INVITE_CODE_REGEX, required=False)
    profile = OnboardingProfileSerializer(required=False)
    consents = ConsentInputSerializer(many=True, required=False)
    device = DeviceInfoSerializer(required=False)


class MfaVerifySerializer(serializers.Serializer[Any]):
    mfa_token = serializers.CharField(max_length=512)
    code = serializers.RegexField(MFA_CODE_REGEX)
    device = DeviceInfoSerializer(required=False)


class MfaCodeSerializer(serializers.Serializer[Any]):
    code = serializers.RegexField(MFA_CODE_REGEX)


class RefreshSerializer(serializers.Serializer[Any]):
    refresh = serializers.CharField(max_length=2048)


class LogoutSerializer(serializers.Serializer[Any]):
    all_devices = serializers.BooleanField(default=False)


class EmailSerializer(serializers.Serializer[Any]):
    email = serializers.EmailField(max_length=254)


class ResetPasswordSerializer(serializers.Serializer[Any]):
    token = serializers.CharField(max_length=256)
    password = serializers.CharField(min_length=10, max_length=128, trim_whitespace=False)


class TokenSerializer(serializers.Serializer[Any]):
    token = serializers.CharField(max_length=256)


class InviteCodeSerializer(serializers.Serializer[Any]):
    code = serializers.RegexField(INVITE_CODE_REGEX)


class CitySearchSerializer(serializers.Serializer[Any]):
    q = serializers.CharField(min_length=1, max_length=60, required=False)
    country = serializers.CharField(min_length=2, max_length=2, required=False)


class ProfileUpdateSerializer(serializers.Serializer[Any]):
    first_name = serializers.CharField(min_length=1, max_length=40, required=False)
    last_name = serializers.CharField(min_length=1, max_length=40, required=False)
    birth_date = serializers.DateField(required=False)
    sex = serializers.ChoiceField(choices=Sex.choices, required=False)
    city_id = serializers.UUIDField(required=False, allow_null=True)
    city_label = serializers.CharField(max_length=80, required=False, allow_null=True, allow_blank=True)
    height_cm = serializers.DecimalField(max_digits=5, decimal_places=1, min_value=100, max_value=250, required=False)
    target_weight_kg = serializers.DecimalField(
        max_digits=5, decimal_places=2, min_value=30, max_value=300, required=False
    )
    goals = serializers.ListField(
        child=serializers.ChoiceField(choices=Goal.choices), min_length=1, max_length=5, required=False
    )
    activity_adjustment = serializers.BooleanField(required=False)
    locale = serializers.ChoiceField(choices=Locale.choices, required=False)
    theme = serializers.ChoiceField(choices=Theme.choices, required=False)
    unit_weight = serializers.ChoiceField(choices=[("kg", "kg"), ("lb", "lb")], required=False)
    unit_height = serializers.ChoiceField(choices=[("cm", "cm"), ("ft", "ft")], required=False)
    unit_volume = serializers.ChoiceField(choices=[("cl", "cl"), ("oz", "oz")], required=False)

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        if not attrs:
            raise serializers.ValidationError("at least one field", code="min_properties")
        return attrs


class ChangePasswordSerializer(serializers.Serializer[Any]):
    current_password = serializers.CharField(max_length=128, required=False, trim_whitespace=False)
    new_password = serializers.CharField(min_length=10, max_length=128, trim_whitespace=False)


class ChangeEmailSerializer(serializers.Serializer[Any]):
    email = serializers.EmailField(max_length=254)
    password = serializers.CharField(max_length=128, required=False, trim_whitespace=False)


class ConsentUpdateSerializer(serializers.Serializer[Any]):
    consents = ConsentInputSerializer(many=True, min_length=1)


class AccountDeletionSerializer(serializers.Serializer[Any]):
    confirm = serializers.ChoiceField(choices=[("DELETE", "DELETE")])
    password = serializers.CharField(max_length=128, required=False, trim_whitespace=False)
    reason = serializers.CharField(max_length=500, required=False, allow_blank=True)


class DeletionByEmailSerializer(serializers.Serializer[Any]):
    email = serializers.EmailField(max_length=254)
    captcha = serializers.CharField(max_length=2048)


class UploadRefSerializer(serializers.Serializer[Any]):
    upload_id = serializers.UUIDField()


class UploadRequestSerializer(serializers.Serializer[Any]):
    kind = serializers.ChoiceField(choices=["meal_photo", "avatar", "support_attachment"])
    content_type = serializers.ChoiceField(choices=["image/jpeg", "image/png", "image/webp", "image/heic"])
    size = serializers.IntegerField(min_value=1, max_value=8 * 1024 * 1024)


# ───────────────────────── Sorties ─────────────────────────


def city_out(city: Any) -> dict[str, Any] | None:
    if city is None:
        return None
    return {"id": city.id, "name": resolve(city.name), "country": city.country, "timezone": city.timezone}


def image_out(upload: Any) -> dict[str, Any] | None:
    if upload is None or upload.status != "ready":
        return None
    out: dict[str, Any] = {"url": presign_download(key=upload.storage_key)}
    if upload.width:
        out["width"] = upload.width
    if upload.height:
        out["height"] = upload.height
    return out


def legal_ref_out(document: Any) -> dict[str, Any]:
    return {"kind": document.kind, "version": document.version, "title": resolve(document.title)}


def tokens_out(pair: Any) -> dict[str, Any]:
    return pair.as_dict()


TARGET_WARNINGS: dict[str, Any] = {
    "target_above_current_for_loss": _("Ton poids cible est supérieur à ton poids actuel alors que tu veux perdre du poids."),
    "target_below_current_for_gain": _("Ton poids cible est inférieur à ton poids actuel alors que tu veux prendre de la masse."),
}


def targets_out(target: Any) -> dict[str, Any] | None:
    if target is None:
        return None
    return {
        "kcal": target.base_kcal,
        "protein_g": target.protein_g,
        "carbs_g": target.carbs_g,
        "fat_g": target.fat_g,
        "fiber_g": target.fiber_g,
        "salt_max_g": float(target.salt_max_g),
        "water_ml": target.water_ml,
        "bmr_kcal": target.bmr_kcal,
        "valid_from": target.valid_from,
        "warning": str(TARGET_WARNINGS[target.warning]) if target.warning in TARGET_WARNINGS else None,
    }


def me_out(*, user: Any, age: int, target: Any, entitlement: Any, pending: list[Any]) -> dict[str, Any]:
    profile = user.profile
    return {
        "id": user.id,
        "email": user.email,
        "email_verified": user.email_verified_at is not None,
        "has_password": user.has_usable_password(),
        "locale": user.locale,
        "created_at": user.created_at,
        "profile": {
            "first_name": profile.first_name,
            "last_name": profile.last_name,
            "initials": profile.initials,
            "avatar": image_out(profile.avatar),
            "birth_date": profile.birth_date,
            "age": age,
            "sex": profile.sex,
            "city": city_out(profile.city),
            "city_label": profile.city_label or None,
            "height_cm": float(profile.height_cm),
            "current_weight_kg": float(profile.current_weight_kg),
            "target_weight_kg": float(profile.target_weight_kg),
            "goals": list(profile.goals),
            "activity_adjustment": profile.activity_adjustment,
            "timezone": profile.timezone,
        },
        "targets": targets_out(target),
        "entitlements": entitlement.as_dict(),
        "preferences": {
            "theme": profile.theme,
            "unit_weight": profile.unit_weight,
            "unit_height": profile.unit_height,
            "unit_volume": profile.unit_volume,
        },
        "pending_documents": [legal_ref_out(d) for d in pending],
    }


def session_out(session: Any, *, current_id: Any) -> dict[str, Any]:
    return {
        "id": session.id,
        "device_name": session.device_name,
        "platform": session.platform,
        "app_version": session.app_version,
        "city": session.city or None,
        "last_used_at": session.last_used_at,
        "current": session.id == current_id,
    }
