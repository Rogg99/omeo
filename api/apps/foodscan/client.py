"""
Client OpenRouter (API compatible OpenAI) pour le scan.

- Délai maximal par appel, nouvelles tentatives à délai croissant sur les
  erreurs passagères (429, 5xx, coupure réseau).
- Coupe-circuit : après plusieurs échecs d'affilée, on cesse d'appeler le
  fournisseur pendant un moment et on répond tout de suite `ai_unavailable`,
  plutôt que de faire attendre chaque utilisateur jusqu'au délai maximal.
- Le coût réel est demandé à OpenRouter (`usage.include`) et conservé pour le
  tableau de bord.

Le module ne connaît ni l'ORM ni les modèles : `services` lui passe les
messages et reçoit le texte brut.
"""

from __future__ import annotations

import threading
import time
from dataclasses import dataclass
from typing import Any, Protocol

import httpx

RETRY_STATUSES = {408, 409, 425, 429, 500, 502, 503, 504}


class ProviderError(RuntimeError):
    """Le fournisseur a répondu une erreur ou une réponse inexploitable."""


class ProviderTimeoutError(ProviderError):
    """Le fournisseur n'a pas répondu à temps."""


class ProviderUnavailableError(ProviderError):
    """Coupe-circuit ouvert ou clé absente : aucun appel n'est tenté."""


@dataclass(frozen=True, slots=True)
class Completion:
    content: str
    model: str
    tokens_in: int
    tokens_out: int
    cost_usd_micros: int | None
    raw: dict[str, Any]


class VisionClient(Protocol):
    def complete(self, *, messages: list[dict[str, Any]], model: str) -> Completion: ...


class CircuitBreaker:
    def __init__(self, *, failure_threshold: int = 5, cooldown_s: float = 60.0) -> None:
        self.failure_threshold = failure_threshold
        self.cooldown_s = cooldown_s
        self._failures = 0
        self._open_until = 0.0
        self._lock = threading.Lock()

    def allow(self) -> bool:
        with self._lock:
            return time.monotonic() >= self._open_until

    def success(self) -> None:
        with self._lock:
            self._failures = 0
            self._open_until = 0.0

    def failure(self) -> None:
        with self._lock:
            self._failures += 1
            if self._failures >= self.failure_threshold:
                self._open_until = time.monotonic() + self.cooldown_s
                self._failures = 0


_breaker = CircuitBreaker()


class OpenRouterClient:
    def __init__(
        self,
        *,
        api_key: str,
        base_url: str = "https://openrouter.ai/api/v1",
        timeout_s: float = 30.0,
        max_retries: int = 2,
        app_name: str = "Omeo",
        breaker: CircuitBreaker | None = None,
        transport: httpx.BaseTransport | None = None,
        sleep: Any = time.sleep,
    ) -> None:
        self.api_key = api_key
        self.base_url = base_url.rstrip("/")
        self.timeout_s = timeout_s
        self.max_retries = max_retries
        self.app_name = app_name
        self.breaker = breaker or _breaker
        self._transport = transport
        self._sleep = sleep

    def complete(self, *, messages: list[dict[str, Any]], model: str) -> Completion:
        if not self.api_key or not model:
            raise ProviderUnavailableError("Clé OpenRouter ou modèle de vision non configuré.")
        if not self.breaker.allow():
            raise ProviderUnavailableError("Fournisseur IA momentanément coupé après des échecs répétés.")

        body = {
            "model": model,
            "messages": messages,
            "temperature": 0.1,
            "max_tokens": 1500,
            "response_format": {"type": "json_object"},
            "usage": {"include": True},
        }
        headers = {"Authorization": f"Bearer {self.api_key}", "X-Title": self.app_name}

        last_error: ProviderError | None = None
        with httpx.Client(timeout=self.timeout_s, transport=self._transport) as http:
            for attempt in range(self.max_retries + 1):
                if attempt:
                    self._sleep(min(2 ** (attempt - 1), 8))
                try:
                    response = http.post(f"{self.base_url}/chat/completions", json=body, headers=headers)
                except httpx.TimeoutException:
                    last_error = ProviderTimeoutError("Délai dépassé chez le fournisseur IA.")
                    continue
                except httpx.HTTPError as exc:
                    last_error = ProviderError(f"Erreur réseau : {exc.__class__.__name__}")
                    continue

                if response.status_code in RETRY_STATUSES:
                    last_error = ProviderError(f"Fournisseur IA : HTTP {response.status_code}")
                    continue
                if response.status_code >= 400:
                    # 400/401/402/403 : rejouer n'y changerait rien.
                    self.breaker.failure()
                    raise ProviderError(f"Fournisseur IA : HTTP {response.status_code}")

                completion = self._parse(response)
                self.breaker.success()
                return completion

        self.breaker.failure()
        raise last_error or ProviderError("Échec de l'appel au fournisseur IA.")

    @staticmethod
    def _parse(response: httpx.Response) -> Completion:
        try:
            payload = response.json()
            content = payload["choices"][0]["message"]["content"]
        except (ValueError, KeyError, IndexError, TypeError) as exc:
            raise ProviderError("Réponse du fournisseur IA illisible.") from exc
        if not isinstance(content, str) or not content.strip():
            raise ProviderError("Réponse vide du fournisseur IA.")
        usage = payload.get("usage") or {}
        cost = usage.get("cost")
        return Completion(
            content=content,
            model=str(payload.get("model") or ""),
            tokens_in=int(usage.get("prompt_tokens") or 0),
            tokens_out=int(usage.get("completion_tokens") or 0),
            cost_usd_micros=round(float(cost) * 1_000_000) if cost is not None else None,
            raw=payload,
        )
