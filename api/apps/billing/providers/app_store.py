"""
App Store : vérification des JWS signés par Apple (StoreKit 2, App Store Server Notifications v2).

La chaîne `x5c` de l'en-tête est vérifiée jusqu'au certificat racine Apple épinglé (`APPLE_ROOT_CA_PEM`), puis la
signature ES256 du JWS avec la clé du certificat feuille. L'identifiant du bundle est contrôlé.
"""

from __future__ import annotations

import base64
from datetime import UTC, datetime
from typing import Any, Final

import jwt
from cryptography import x509
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import Encoding
from django.conf import settings

from apps.billing.providers.base import InvalidSignatureError, VerifiedSubscription

CHAIN_LENGTH: Final = 3


def _load_chain(token: str) -> list[x509.Certificate]:
    header = jwt.get_unverified_header(token)
    chain = header.get("x5c") or []
    if len(chain) != CHAIN_LENGTH:
        raise InvalidSignatureError("unexpected x5c chain")
    return [x509.load_der_x509_certificate(base64.b64decode(cert)) for cert in chain]


def _verify_issued_by(child: x509.Certificate, parent: x509.Certificate, now: datetime) -> None:
    if not child.not_valid_before_utc <= now <= child.not_valid_after_utc:
        raise InvalidSignatureError("certificate expired")
    public_key = parent.public_key()
    if not isinstance(public_key, ec.EllipticCurvePublicKey) or child.signature_hash_algorithm is None:
        raise InvalidSignatureError("unexpected key type")
    try:
        public_key.verify(child.signature, child.tbs_certificate_bytes, ec.ECDSA(child.signature_hash_algorithm))
    except InvalidSignature as exc:
        raise InvalidSignatureError("broken certificate chain") from exc


def decode_signed(token: str, *, now: datetime | None = None) -> dict[str, Any]:
    root_pem: str = settings.APPLE_ROOT_CA_PEM
    if not root_pem:
        raise InvalidSignatureError("APPLE_ROOT_CA_PEM is not configured")
    now = now or datetime.now(UTC)
    leaf, intermediate, root = _load_chain(token)
    pinned = x509.load_pem_x509_certificate(root_pem.encode())
    if root.public_bytes(Encoding.DER) != pinned.public_bytes(Encoding.DER):
        raise InvalidSignatureError("unknown root certificate")
    _verify_issued_by(intermediate, root, now)
    _verify_issued_by(leaf, intermediate, now)
    try:
        payload: dict[str, Any] = jwt.decode(token, leaf.public_key(), algorithms=["ES256"])  # type: ignore[arg-type]
    except jwt.PyJWTError as exc:
        raise InvalidSignatureError("invalid JWS signature") from exc
    bundle_id = payload.get("bundleId") or (payload.get("data") or {}).get("bundleId")
    if bundle_id and bundle_id != settings.APPLE_BUNDLE_ID:
        raise InvalidSignatureError("unexpected bundle id")
    return payload


def _ms(value: Any) -> datetime:
    return datetime.fromtimestamp(int(value or 0) / 1000, tz=UTC)


def subscription_from_transaction(
    transaction: dict[str, Any], *, renewal: dict[str, Any] | None = None, now: datetime | None = None
) -> VerifiedSubscription:
    now = now or datetime.now(UTC)
    expires = _ms(transaction.get("expiresDate"))
    if transaction.get("revocationDate"):
        status = "refunded"
    elif expires > now:
        status = "active" if (renewal or {}).get("autoRenewStatus", 1) == 1 else "canceled"
    elif renewal and renewal.get("isInBillingRetryPeriod"):
        status = "grace"
    else:
        status = "expired"
    return VerifiedSubscription(
        channel="app_store",
        external_id=str(transaction["originalTransactionId"]),
        product_id=str(transaction.get("productId", "")),
        status=status,
        period_start=_ms(transaction.get("purchaseDate")),
        period_end=expires,
        auto_renew=(renewal or {}).get("autoRenewStatus", 1) == 1,
        event_at=_ms(transaction.get("signedDate")) if transaction.get("signedDate") else now,
        raw={"transactionId": transaction.get("transactionId"), "type": transaction.get("type")},
    )


def parse_notification(signed_payload: str) -> tuple[str, datetime, str, VerifiedSubscription | None]:
    """(identifiant, date, type, abonnement) d'une notification v2."""
    payload = decode_signed(signed_payload)
    data = payload.get("data") or {}
    subscription = None
    if data.get("signedTransactionInfo"):
        transaction = decode_signed(data["signedTransactionInfo"])
        renewal = decode_signed(data["signedRenewalInfo"]) if data.get("signedRenewalInfo") else None
        subscription = subscription_from_transaction(transaction, renewal=renewal)
    notification_type = str(payload.get("notificationType", ""))
    return str(payload["notificationUUID"]), _ms(payload.get("signedDate")), notification_type, subscription
