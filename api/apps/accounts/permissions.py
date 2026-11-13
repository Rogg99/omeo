"""
Catalogue des permissions et correspondance rôle → permissions (docs/technique/controle-acces.md).

Constante versionnée, relue en revue de code : ce n'est PAS une table modifiable depuis l'admin.
Le code vérifie des permissions (`billing.refund`), jamais des rôles.
"""

from __future__ import annotations

from typing import Any, Final, Literal

Permission = Literal[
    "dashboard.product",
    "dashboard.finance",
    "dashboard.support",
    "users.view",
    "users.view_health",
    "users.resend_verification",
    "users.send_password_reset",
    "users.extend_trial",
    "users.grant_plus_days",
    "users.reset_quota",
    "users.suspend",
    "users.export_data",
    "users.delete_data",
    "content.view",
    "content.edit",
    "content.publish",
    "content.publish_own",
    "content.translate",
    "feedback.view",
    "feedback.resolve",
    "billing.view",
    "billing.plans_edit",
    "billing.quotas_edit",
    "billing.refund",
    "billing.promo_manage",
    "support.view",
    "support.reply",
    "support.templates_manage",
    "campaigns.view",
    "campaigns.edit",
    "campaigns.schedule",
    "approvals.decide",
    "settings.view",
    "settings.edit",
    "team.manage",
    "audit.view",
]

RoleName = Literal["superadmin", "content", "support", "finance", "moderation"]

ALL_PERMISSIONS: Final[frozenset[Permission]] = frozenset(Permission.__args__)  # type: ignore[attr-defined]

# `content.publish_own` n'est attribuée à aucun rôle par défaut.
ROLE_PERMISSIONS: Final[dict[RoleName, frozenset[Permission]]] = {
    "superadmin": ALL_PERMISSIONS - {"content.publish_own"},
    "content": frozenset(
        {
            "dashboard.product",
            "content.view",
            "content.edit",
            "content.publish",
            "content.translate",
            "feedback.view",
            "campaigns.view",
            "campaigns.edit",
            "campaigns.schedule",
            "approvals.decide",
            "settings.view",
        }
    ),
    "support": frozenset(
        {
            "dashboard.product",
            "dashboard.support",
            "users.view",
            "users.view_health",
            "users.resend_verification",
            "users.send_password_reset",
            "users.extend_trial",
            "users.reset_quota",
            "content.view",
            "billing.view",
            "support.view",
            "support.reply",
            "support.templates_manage",
        }
    ),
    "finance": frozenset(
        {
            "dashboard.product",
            "dashboard.finance",
            "users.view",
            "users.grant_plus_days",
            "users.reset_quota",
            "billing.view",
            "billing.plans_edit",
            "billing.quotas_edit",
            "billing.refund",
            "billing.promo_manage",
            "approvals.decide",
            "settings.view",
        }
    ),
    "moderation": frozenset({"dashboard.product", "content.view", "feedback.view", "feedback.resolve"}),
}

# `approvals.decide` est limité au domaine du rôle (contenu, finance) ; le superadmin décide partout.
ROLE_APPROVAL_DOMAINS: Final[dict[RoleName, frozenset[str]]] = {
    "superadmin": frozenset({"content", "finance", "settings"}),
    "content": frozenset({"content"}),
    "finance": frozenset({"finance"}),
    "support": frozenset(),
    "moderation": frozenset(),
}

# Permissions exigeant un TOTP de moins de 15 min (🔐).
STEP_UP_PERMISSIONS: Final[frozenset[Permission]] = frozenset(
    {
        "users.view_health",
        "users.grant_plus_days",
        "users.suspend",
        "users.export_data",
        "users.delete_data",
        "billing.refund",
        "campaigns.schedule",
        "approvals.decide",
        "settings.edit",
        "team.manage",
    }
)


def roles_of(user: Any) -> list[RoleName]:
    if not getattr(user, "is_staff", False):
        return []
    cached: list[RoleName] | None = getattr(user, "_staff_roles_cache", None)
    if cached is None:
        cached = sorted(user.staff_roles.values_list("role", flat=True))
        user._staff_roles_cache = cached
    return cached


def permissions_for_roles(roles: list[RoleName]) -> frozenset[Permission]:
    granted: set[Permission] = set()
    for role in roles:
        granted |= ROLE_PERMISSIONS.get(role, frozenset())
    return frozenset(granted)


def permissions_for_user(user: Any) -> frozenset[Permission]:
    return permissions_for_roles(roles_of(user))


def has_permission(user: Any, permission: Permission) -> bool:
    return permission in permissions_for_user(user)


def can_decide_domain(user: Any, domain: str) -> bool:
    if not has_permission(user, "approvals.decide"):
        return False
    return any(domain in ROLE_APPROVAL_DOMAINS.get(role, frozenset()) for role in roles_of(user))
