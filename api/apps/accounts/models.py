"""Comptes, profils, villes, sessions, documents légaux, consentements, parrainage, équipe et double authentification."""

from __future__ import annotations

from typing import Any, ClassVar

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.postgres.fields import ArrayField
from django.contrib.postgres.indexes import GinIndex
from django.core.validators import MaxValueValidator, MinValueValidator, RegexValidator
from django.db import models
from django.db.models import Q
from django.db.models.functions import Lower

from apps.core.i18n import I18nTextField
from apps.core.models import BaseModel


class Locale(models.TextChoices):
    FR = "fr"
    EN = "en"
    ES = "es"
    PT = "pt"
    AR = "ar"
    ZH = "zh"
    JA = "ja"
    DE = "de"


class UserManager(BaseUserManager["User"]):
    use_in_migrations = True

    def create_user(self, email: str, password: str | None = None, **extra: Any) -> User:
        if not email:
            raise ValueError("email is required")
        user = self.model(email=self.normalize_email(email).lower(), **extra)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save(using=self._db)
        return user


class User(AbstractBaseUser, BaseModel):
    email = models.EmailField(max_length=254, unique=True)
    email_verified_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)  # false = suspendu
    is_staff = models.BooleanField(default=False)
    locale = models.CharField(max_length=2, choices=Locale.choices, default=Locale.FR)
    last_seen_at = models.DateTimeField(null=True, blank=True)
    suspended_at = models.DateTimeField(null=True, blank=True)
    deletion_requested_at = models.DateTimeField(null=True, blank=True)
    deletion_scheduled_at = models.DateTimeField(null=True, blank=True, db_index=True)

    USERNAME_FIELD = "email"
    EMAIL_FIELD = "email"
    REQUIRED_FIELDS: ClassVar[list[str]] = []

    objects: ClassVar[UserManager] = UserManager()

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(Lower("email"), name="user_email_ci_uniq"),
        ]

    def __str__(self) -> str:
        return str(self.pk)

    @property
    def is_suspended(self) -> bool:
        return not self.is_active


class City(BaseModel):
    name = I18nTextField()
    country = models.CharField(max_length=2, db_index=True)
    timezone = models.CharField(max_length=64)
    is_suggested = models.BooleanField(default=False)

    class Meta:
        verbose_name_plural = "cities"
        indexes: ClassVar[list[models.Index]] = [GinIndex(fields=["name"], name="city_name_gin")]

    def __str__(self) -> str:
        return str(self.name.get("fr", self.pk))


class Sex(models.TextChoices):
    MALE = "male"
    FEMALE = "female"


class Goal(models.TextChoices):
    LOSE_WEIGHT = "lose_weight"
    GAIN_MUSCLE = "gain_muscle"
    EAT_BALANCED = "eat_balanced"
    PREVENT_DIABETES = "prevent_diabetes"
    PREVENT_HYPERTENSION = "prevent_hypertension"


class Theme(models.TextChoices):
    SYSTEM = "system"
    LIGHT = "light"
    DARK = "dark"


class Profile(BaseModel):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    first_name = models.CharField(max_length=40)
    last_name = models.CharField(max_length=40)
    birth_date = models.DateField()
    sex = models.CharField(max_length=6, choices=Sex.choices)
    city = models.ForeignKey(City, null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    city_label = models.CharField(max_length=80, blank=True)
    country = models.CharField(max_length=2, blank=True)
    timezone = models.CharField(max_length=64, default="Africa/Abidjan")
    height_cm = models.DecimalField(
        max_digits=5, decimal_places=1, validators=[MinValueValidator(100), MaxValueValidator(250)]
    )
    current_weight_kg = models.DecimalField(max_digits=5, decimal_places=2)
    target_weight_kg = models.DecimalField(
        max_digits=5, decimal_places=2, validators=[MinValueValidator(30), MaxValueValidator(300)]
    )
    goals = ArrayField(models.CharField(max_length=24, choices=Goal.choices), default=list)
    activity_adjustment = models.BooleanField(default=True)
    avatar = models.ForeignKey(
        "meals.Upload", null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
    unit_weight = models.CharField(max_length=2, choices=[("kg", "kg"), ("lb", "lb")], default="kg")
    unit_height = models.CharField(max_length=2, choices=[("cm", "cm"), ("ft", "ft")], default="cm")
    unit_volume = models.CharField(max_length=2, choices=[("cl", "cl"), ("oz", "oz")], default="cl")
    theme = models.CharField(max_length=6, choices=Theme.choices, default=Theme.SYSTEM)

    def __str__(self) -> str:
        return f"profile:{self.user_id}"

    @property
    def initials(self) -> str:
        return f"{self.first_name[:1]}{self.last_name[:1]}".upper()


class SocialProvider(models.TextChoices):
    GOOGLE = "google"
    APPLE = "apple"


class SocialAccount(BaseModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="social_accounts")
    provider = models.CharField(max_length=8, choices=SocialProvider.choices)
    subject = models.CharField(max_length=255)
    email = models.EmailField(blank=True)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["provider", "subject"], name="social_provider_subject_uniq"),
        ]


class Platform(models.TextChoices):
    ANDROID = "android"
    IOS = "ios"
    WEB = "web"
    ADMIN = "admin"


class Session(BaseModel):
    """Appareil connecté. `refresh_jti` est le dernier jeton de renouvellement émis : tout autre jti est un rejeu."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="sessions")
    refresh_jti = models.CharField(max_length=64, unique=True)
    mfa_verified_at = models.DateTimeField(null=True, blank=True)
    device_name = models.CharField(max_length=80, blank=True)
    platform = models.CharField(max_length=8, choices=Platform.choices, default=Platform.ANDROID)
    app_version = models.CharField(max_length=20, blank=True)
    ip = models.GenericIPAddressField(null=True, blank=True)
    city = models.CharField(max_length=80, blank=True)
    last_used_at = models.DateTimeField()
    expires_at = models.DateTimeField()
    revoked_at = models.DateTimeField(null=True, blank=True)
    revoked_reason = models.CharField(max_length=32, blank=True)

    class Meta:
        indexes: ClassVar[list[models.Index]] = [
            models.Index(fields=["user", "revoked_at"], name="session_user_active_idx"),
        ]

    @property
    def is_active(self) -> bool:
        return self.revoked_at is None


class LegalKind(models.TextChoices):
    TERMS = "terms"
    PRIVACY = "privacy"
    COOKIES = "cookies"
    LEGAL_NOTICE = "legal_notice"


class LegalDocument(BaseModel):
    kind = models.CharField(max_length=16, choices=LegalKind.choices)
    version = models.PositiveIntegerField()
    title = I18nTextField()
    body = I18nTextField()
    published_at = models.DateTimeField(null=True, blank=True)
    requires_reaccept = models.BooleanField(default=False)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["kind", "version"], name="legal_kind_version_uniq"),
        ]


class ConsentKind(models.TextChoices):
    TERMS = "terms"
    PRIVACY = "privacy"
    HEALTH_DATA = "health_data"
    MARKETING = "marketing"


REQUIRED_CONSENTS: tuple[str, ...] = (ConsentKind.TERMS, ConsentKind.PRIVACY, ConsentKind.HEALTH_DATA)
NON_WITHDRAWABLE_CONSENTS: tuple[str, ...] = (ConsentKind.TERMS, ConsentKind.PRIVACY)


class Consent(BaseModel):
    """Ajout seul : l'état courant est le dernier enregistrement par `kind`."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="consents")
    kind = models.CharField(max_length=16, choices=ConsentKind.choices)
    document = models.ForeignKey(LegalDocument, null=True, blank=True, on_delete=models.PROTECT, related_name="+")
    granted = models.BooleanField()
    ip = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=255, blank=True)

    class Meta:
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["user", "kind", "-created_at"])]

    def save(self, *args: Any, **kwargs: Any) -> None:
        if not self._state.adding:
            raise ValueError("Consent is append-only")
        super().save(*args, **kwargs)


class ReferralCode(BaseModel):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="referral_code")
    code = models.CharField(
        max_length=10, unique=True, validators=[RegexValidator(r"^[A-Z0-9]{4,10}$")]
    )


class ReferralStatus(models.TextChoices):
    PENDING = "pending"
    VALIDATED = "validated"
    REJECTED = "rejected"


class ReferralRejection(models.TextChoices):
    SAME_DEVICE = "same_device"
    SELF = "self"
    CAP_REACHED = "cap_reached"
    EXPIRED = "expired"


class Referral(BaseModel):
    referrer = models.ForeignKey(User, on_delete=models.CASCADE, related_name="referrals")
    referee = models.OneToOneField(User, on_delete=models.CASCADE, related_name="referred_by")
    code = models.ForeignKey(ReferralCode, on_delete=models.CASCADE, related_name="referrals")
    status = models.CharField(max_length=10, choices=ReferralStatus.choices, default=ReferralStatus.PENDING)
    rejected_reason = models.CharField(max_length=12, choices=ReferralRejection.choices, blank=True)
    validated_at = models.DateTimeField(null=True, blank=True)
    reward_days = models.PositiveSmallIntegerField(default=0)


class DeviceFingerprint(BaseModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="fingerprints")
    hash = models.CharField(max_length=128, db_index=True)
    first_seen_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "hash"], name="fingerprint_user_hash_uniq"),
        ]


class Role(models.TextChoices):
    SUPERADMIN = "superadmin"
    CONTENT = "content"
    SUPPORT = "support"
    FINANCE = "finance"
    MODERATION = "moderation"


class StaffRole(BaseModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="staff_roles")
    role = models.CharField(max_length=12, choices=Role.choices)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "role"], name="staff_user_role_uniq"),
        ]


class StaffInvitation(BaseModel):
    email = models.EmailField()
    roles = ArrayField(models.CharField(max_length=12, choices=Role.choices))
    token_hash = models.CharField(max_length=64, unique=True)
    invited_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name="+")
    expires_at = models.DateTimeField()
    accepted_at = models.DateTimeField(null=True, blank=True)


class TOTPDevice(BaseModel):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="totp_device")
    secret_encrypted = models.TextField()
    confirmed_at = models.DateTimeField(null=True, blank=True)
    last_used_step = models.BigIntegerField(default=0)  # anti-rejeu d'un même code


class RecoveryCode(BaseModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="recovery_codes")
    code_hash = models.CharField(max_length=128)
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes: ClassVar[list[models.Index]] = [
            models.Index(fields=["user"], condition=Q(used_at__isnull=True), name="recovery_unused_idx"),
        ]


class OneTimeTokenPurpose(models.TextChoices):
    EMAIL_VERIFY = "email_verify"
    PASSWORD_RESET = "password_reset"
    EMAIL_CHANGE = "email_change"
    ACCOUNT_DELETION = "account_deletion"


class OneTimeToken(BaseModel):
    """Jeton à usage unique envoyé par email. Seule son empreinte SHA-256 est stockée."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="+")
    purpose = models.CharField(max_length=16, choices=OneTimeTokenPurpose.choices)
    token_hash = models.CharField(max_length=64, unique=True)
    payload = models.JSONField(default=dict)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)
