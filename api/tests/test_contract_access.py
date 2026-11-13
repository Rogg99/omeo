"""
Le contrat est la spécification du contrôle d'accès (docs/technique/controle-acces.md).

Pour CHAQUE opération de contracts/openapi.yaml routée par l'API :
- `security: []` ⇔ vue publique ; sinon authentification obligatoire ;
- `x-permission` ⇔ `HasPermission` et la même permission déclarée sur la vue ;
- `x-step-up` ⇔ `RequiresStepUp` ; `x-email-verified` ⇔ `RequiresVerifiedEmail` ;
- `x-entitlement` ⇔ `RequiresFeature(feature)`, ou contrôle conditionnel déclaré (`conditional_entitlements`) ;
- paramètre `Idempotency-Key` ⇔ méthode décorée par `@idempotent`.
Puis des tests de comportement : rôle refusé (403 forbidden_role), compte Free (403 plan_required), sans step-up
(401 step_up_required). Enfin, aucune route de l'API n'existe hors du contrat.
"""

from __future__ import annotations

import re
import uuid
from collections.abc import Callable, Iterator
from dataclasses import dataclass
from datetime import timedelta
from pathlib import Path
from typing import Any

import pytest
import yaml
from django.urls import URLPattern, URLResolver, get_resolver, resolve
from django.urls.exceptions import Resolver404
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import Role, User
from apps.accounts.permissions import ROLE_PERMISSIONS
from apps.billing.models import Trial
from apps.billing.services import invalidate_entitlement
from apps.core.permissions import AUTHENTICATED_STAFF, HasPermission, RequiresStepUp, RequiresVerifiedEmail
from apps.core.views import PublicAPIView
from conftest import login_client

CONTRACT = Path(__file__).resolve().parents[2] / "contracts" / "openapi.yaml"
METHODS = ("get", "post", "put", "patch", "delete")
SAMPLE_PATH_VALUES: dict[str, str] = {
    "id": str(uuid.UUID(int=1)),
    "date": "2026-11-09",
    "type": "recipes",
    "code": "plus_monthly",
    "token": "token-sample",
    "action": "schedule",
    "kind": "terms",
}
INTERNAL_ROUTES = {"/api/v1/health", "/api/v1/schema/", "/api/v1/docs/"}


@dataclass(frozen=True)
class Operation:
    path: str
    method: str
    spec: dict[str, Any]

    @property
    def operation_id(self) -> str:
        return str(self.spec["operationId"])

    @property
    def url(self) -> str:
        return "/api/v1" + re.sub(r"\{(\w+)\}", lambda m: SAMPLE_PATH_VALUES[m.group(1)], self.path)

    def __str__(self) -> str:
        return self.operation_id


def _load_contract() -> dict[str, Any]:
    return yaml.safe_load(CONTRACT.read_text(encoding="utf-8"))  # type: ignore[no-any-return]


def _operations() -> Iterator[Operation]:
    for path, item in _load_contract()["paths"].items():
        for method in METHODS:
            if method in item:
                yield Operation(path=path, method=method, spec=item[method])


def _view_class(op: Operation) -> type[Any] | None:
    try:
        match = resolve(op.url)
    except Resolver404:
        return None
    view_class: type[Any] | None = getattr(match.func, "view_class", None)
    if view_class is None or not hasattr(view_class, op.method):
        return None
    return view_class


IMPLEMENTED = [op for op in _operations() if _view_class(op) is not None]


def _permission_classes(view: type[Any]) -> list[type[Any]]:
    return list(view.permission_classes)


def _declared_permission(view: type[Any], method: str) -> str | None:
    permission_map: dict[str, str] | None = getattr(view, "permission_map", None)
    if permission_map and method.upper() in permission_map:
        return permission_map[method.upper()]
    return getattr(view, "required_permission", None)


@pytest.mark.parametrize("op", IMPLEMENTED, ids=str)
def test_public_matches_security(op: Operation) -> None:
    view = _view_class(op)
    assert view is not None
    is_public = op.spec.get("security") == []
    assert issubclass(view, PublicAPIView) is is_public, f"{op}: security {'[]' if is_public else 'bearer'}"


@pytest.mark.parametrize("op", IMPLEMENTED, ids=str)
def test_markers_applied(op: Operation) -> None:
    view = _view_class(op)
    assert view is not None
    classes = _permission_classes(view)
    names = {c.__name__ for c in classes}

    permission = op.spec.get("x-permission")
    if permission:
        assert HasPermission in classes, f"{op}: HasPermission missing"
        assert _declared_permission(view, op.method) == permission, f"{op}: expected {permission}"
    else:
        assert HasPermission not in classes, f"{op}: unexpected HasPermission"

    has_step_up = RequiresStepUp in classes
    scoped: set[str] | None = getattr(view, "step_up_actions", None)
    applies_step_up = has_step_up and (scoped is None or op.method.upper() in scoped)
    assert applies_step_up is bool(op.spec.get("x-step-up")), f"{op}: x-step-up"

    assert (RequiresVerifiedEmail in classes) is bool(op.spec.get("x-email-verified")), f"{op}: x-email-verified"

    entitlement = op.spec.get("x-entitlement")
    if entitlement:
        feature = entitlement["feature"]
        if entitlement.get("when"):
            conditional: dict[str, str] = getattr(view, "conditional_entitlements", {})
            assert conditional.get(op.method.upper()) == feature, f"{op}: conditional entitlement {feature}"
        else:
            assert f"RequiresFeature[{feature}]" in names, f"{op}: RequiresFeature[{feature}]"

    wants_idempotency = any(
        p.get("$ref", "").endswith("/IdempotencyKey") for p in op.spec.get("parameters", [])
    )
    method = getattr(view, op.method)
    assert bool(getattr(method, "idempotent", False)) is wants_idempotency, f"{op}: Idempotency-Key"


def _routes(resolver: URLResolver, prefix: str = "") -> Iterator[str]:
    for pattern in resolver.url_patterns:
        route = prefix + str(pattern.pattern)
        if isinstance(pattern, URLResolver):
            yield from _routes(pattern, route)
        elif isinstance(pattern, URLPattern):
            yield "/" + route


def _to_contract_path(route: str) -> str:
    return re.sub(r"<(?:\w+:)?(\w+)>", r"{\1}", route).removeprefix("/api/v1")


def test_no_route_outside_contract() -> None:
    contract_paths = set(_load_contract()["paths"])
    for route in _routes(get_resolver()):
        if not route.startswith("/api/v1/") or route in INTERNAL_ROUTES:
            continue
        assert _to_contract_path(route) in contract_paths, f"{route} is not in the contract"


# ───────────────────────── Comportement ─────────────────────────

ADMIN_OPS = [op for op in IMPLEMENTED if op.spec.get("x-permission") not in (None, AUTHENTICATED_STAFF)]
ROLE_REFUSALS = [
    (op, role) for op in ADMIN_OPS for role in Role.values if op.spec["x-permission"] not in ROLE_PERMISSIONS[role]
]


def _call(client: APIClient, op: Operation) -> Any:
    return getattr(client, op.method)(op.url, {}, format="json")


@pytest.mark.django_db
@pytest.mark.parametrize(("op", "role"), ROLE_REFUSALS, ids=lambda v: str(v))
def test_role_refused(op: Operation, role: str, make_staff: Callable[..., tuple[User, str]]) -> None:
    staff, _ = make_staff(role)
    response = _call(login_client(staff, mfa_verified=True), op)
    assert response.status_code == 403, op
    assert response.json()["code"] == "forbidden_role"


@pytest.mark.django_db
@pytest.mark.parametrize("op", [op for op in IMPLEMENTED if op.spec.get("x-step-up")], ids=str)
def test_step_up_required(op: Operation, superadmin: tuple[User, str]) -> None:
    staff, _ = superadmin
    response = _call(login_client(staff, mfa_verified=False), op)
    assert response.status_code == 401
    assert response.json()["code"] == "step_up_required"


@pytest.mark.django_db
@pytest.mark.parametrize(
    "op",
    [op for op in IMPLEMENTED if op.spec.get("x-entitlement") and not op.spec["x-entitlement"].get("when")],
    ids=str,
)
def test_free_account_refused(op: Operation, user: User) -> None:
    Trial.objects.filter(user=user).update(ends_at=timezone.now() - timedelta(days=1))
    invalidate_entitlement(user.pk)
    response = _call(login_client(user), op)
    assert response.status_code == 403
    assert response.json()["code"] == "plan_required"
    assert response.json()["meta"]["feature"] == op.spec["x-entitlement"]["feature"]


@pytest.mark.django_db
@pytest.mark.parametrize("op", [op for op in IMPLEMENTED if op.spec.get("security") != []], ids=str)
def test_authentication_required(op: Operation, reference: None) -> None:
    response = _call(APIClient(), op)
    assert response.status_code == 401
    assert response.json()["code"] in {"not_authenticated", "token_expired"}
