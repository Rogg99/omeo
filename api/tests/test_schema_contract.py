"""
Tests de contrat avec schemathesis sur le schéma généré (`/api/v1/schema/`) : pour chaque opération, des requêtes
générées ne doivent jamais provoquer d'erreur serveur, et les codes et corps de réponse doivent respecter le schéma
publié, c'est-à-dire le contrat (apps/core/schema.py).

Lancement : `pytest -m contract` (requiert la base de test et les données de référence).
"""

from __future__ import annotations

from typing import Any

import pytest
import schemathesis
from django.core.management import call_command

from config.wsgi import application

schema = schemathesis.openapi.from_wsgi("/api/v1/schema/", application)


@pytest.fixture(autouse=True)
def _reference(db: Any) -> None:
    call_command("seed_reference", verbosity=0)


@pytest.mark.contract
@schema.parametrize()
def test_api_conforms_to_generated_schema(case: Any) -> None:
    case.call_and_validate(
        checks=[
            schemathesis.checks.not_a_server_error,
            schemathesis.checks.status_code_conformance,
            schemathesis.checks.response_schema_conformance,
        ]
    )
