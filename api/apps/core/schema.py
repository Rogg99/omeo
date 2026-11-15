"""
Schéma OpenAPI servi par `/api/v1/schema/` (post-traitement drf-spectacular).

Le contrat (`contracts/openapi.yaml`) est la source de vérité : pour chaque opération réellement routée par l'API,
la description du contrat (paramètres, corps, réponses, marqueurs d'accès) remplace celle déduite des vues, et les
composants viennent du contrat. Une opération routée mais absente du contrat reste telle que générée, ce qui la fait
apparaître dans `oasdiff` ; une opération du contrat non routée n'est pas publiée.

Ce que garantissent les tests :
- `tests/test_contract_access.py` : chaque route existe dans le contrat, et chaque marqueur est appliqué par la vue ;
- `tests/test_schema_contract.py` (schemathesis) : les réponses réelles respectent ce schéma, donc le contrat.
"""

from __future__ import annotations

import logging
from functools import cache
from pathlib import Path
from typing import Any, Final

import yaml
from django.conf import settings

API_PREFIX: Final = "/api/v1"
METHODS: Final = ("get", "put", "post", "delete", "patch")
logger = logging.getLogger(__name__)


@cache
def load_contract() -> dict[str, Any] | None:
    path = Path(settings.OPENAPI_CONTRACT_PATH)
    if not path.exists():
        logger.warning("contract not found, serving the generated schema", extra={"path": str(path)})
        return None
    with path.open(encoding="utf-8") as handle:
        contract: dict[str, Any] = yaml.safe_load(handle)
    return contract


def align_with_contract(result: dict[str, Any], generator: Any, request: Any, public: bool) -> dict[str, Any]:
    contract = load_contract()
    if contract is None:
        return result
    contract_paths: dict[str, Any] = contract["paths"]
    paths: dict[str, Any] = {}
    for raw_path, item in result.get("paths", {}).items():
        path = raw_path.removeprefix(API_PREFIX) or "/"
        contract_item = contract_paths.get(path)
        if contract_item is None:
            paths[path] = item
            continue
        aligned = {method: contract_item[method] for method in METHODS if method in item and method in contract_item}
        if "parameters" in contract_item:
            aligned["parameters"] = contract_item["parameters"]
        paths[path] = aligned
    return {
        "openapi": contract["openapi"],
        "info": contract["info"],
        "servers": contract.get("servers", []),
        "security": contract.get("security", []),
        "tags": contract.get("tags", []),
        "paths": dict(sorted(paths.items())),
        "components": contract["components"],
    }
