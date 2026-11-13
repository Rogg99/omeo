"""
Classes DRF du contrôle d'accès (docs/technique/controle-acces.md). On vérifie des permissions, jamais des rôles.

- `HasPermission` : lit `required_permission` sur la vue, ou `permission_map[action ou méthode]`.
- `RequiresStepUp` : TOTP de moins de 15 min sur la session, sinon 401 `step_up_required`.
- `RequiresVerifiedEmail` : 403 `email_not_verified`.
- `RequiresFeature(feature)` : droit recalculé à chaque requête (`entitlement_for`), jamais lu dans le JWT.
"""

from __future__ import annotations

from datetime import timedelta
from typing import Any, Final

from django.utils import timezone
from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.views import APIView

from apps.core.errors import EmailNotVerified, ForbiddenRole, NotAuthenticated, PlanRequired, StepUpRequired

STEP_UP_WINDOW: Final = timedelta(minutes=15)
AUTHENTICATED_STAFF: Final = "authenticated_staff"


def required_permission_for(view: APIView, request: Request) -> str | None:
    permission_map: dict[str, str] | None = getattr(view, "permission_map", None)
    if permission_map:
        action = getattr(view, "action", None)
        if action and action in permission_map:
            return permission_map[action]
        method = (request.method or "").upper()
        if method in permission_map:
            return permission_map[method]
    return getattr(view, "required_permission", None)


class HasPermission(BasePermission):
    def has_permission(self, request: Request, view: APIView) -> bool:
        from apps.accounts.permissions import permissions_for_user

        user = request.user
        if not user or not user.is_authenticated:
            raise NotAuthenticated()
        permission = required_permission_for(view, request)
        if permission is None:
            raise ForbiddenRole()
        if not getattr(user, "is_staff", False):
            raise ForbiddenRole()
        if permission == AUTHENTICATED_STAFF:
            return True
        if permission not in permissions_for_user(user):
            raise ForbiddenRole(meta={"permission": permission})
        return True


def step_up_valid(request: Request) -> bool:
    session = getattr(request, "auth_session", None)
    verified_at = getattr(session, "mfa_verified_at", None)
    return verified_at is not None and timezone.now() - verified_at < STEP_UP_WINDOW


class RequiresStepUp(BasePermission):
    """S'applique à toute la vue, ou seulement aux actions/méthodes de `step_up_actions`."""

    def has_permission(self, request: Request, view: APIView) -> bool:
        scoped: set[str] | None = getattr(view, "step_up_actions", None)
        if scoped is not None:
            key = getattr(view, "action", None) or (request.method or "").upper()
            if key not in scoped and (request.method or "").upper() not in scoped:
                return True
        if not step_up_valid(request):
            raise StepUpRequired()
        return True


class RequiresVerifiedEmail(BasePermission):
    def has_permission(self, request: Request, view: APIView) -> bool:
        if getattr(request.user, "email_verified_at", None) is None:
            raise EmailNotVerified()
        return True


def RequiresFeature(feature: str) -> type[BasePermission]:  # noqa: N802 - fabrique de classe, utilisée comme une classe
    class _RequiresFeature(BasePermission):
        required_feature = feature

        def has_permission(self, request: Request, view: APIView) -> bool:
            require_feature(request.user, feature)
            return True

    _RequiresFeature.__name__ = f"RequiresFeature[{feature}]"
    return _RequiresFeature


def require_feature(user: Any, feature: str) -> None:
    """Contrôle conditionnel (`x-entitlement.when`) depuis une vue : 403 `plan_required` si le droit manque."""
    from apps.billing.services import entitlement_for

    if not entitlement_for(user).allows(feature):
        raise PlanRequired(meta={"feature": feature, "upgrade": True})
