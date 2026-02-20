"""Centralized Google Cloud KMS service for all treasury signing operations."""

import logging

from google.cloud import kms
from cryptography.hazmat.primitives.serialization import (
    Encoding,
    PublicFormat,
    load_pem_public_key,
)

from app.core.config import settings

logger = logging.getLogger(__name__)

# Module-level client (lazily initialized)
_kms_client: kms.KeyManagementServiceClient | None = None


def get_kms_client() -> kms.KeyManagementServiceClient:
    """Return the singleton KMS client, initializing from service account credentials."""
    global _kms_client
    if _kms_client is None:
        _kms_client = kms.KeyManagementServiceClient()
    return _kms_client


def _key_version_path(
    project_id: str | None = None,
    location: str | None = None,
    key_ring: str | None = None,
    key_name: str | None = None,
    version: int | None = None,
) -> str:
    """Build KMS key version resource path from config defaults or provided values."""
    _project_id = project_id or settings.KMS_PROJECT_ID
    _location = location or settings.KMS_LOCATION
    _key_ring = key_ring or settings.KMS_KEYRING
    _key_name = key_name or settings.KMS_KEY_NAME
    _version = version if version is not None else settings.KMS_KEY_VERSION
    return (
        f"projects/{_project_id}"
        f"/locations/{_location}"
        f"/keyRings/{_key_ring}"
        f"/cryptoKeys/{_key_name}"
        f"/cryptoKeyVersions/{_version}"
    )


def sign_transaction(
    tx_hash_bytes: bytes,
    key_name: str | None = None,
) -> bytes:
    """Sign a 32-byte hash using the configured KMS asymmetric signing key.

    Args:
        tx_hash_bytes: 32-byte hash to sign (sha256 digest).
        key_name: Override KMS key name. Defaults to settings.KMS_KEY_NAME.

    Returns:
        DER-encoded signature bytes.
    """
    client = get_kms_client()
    key_version = _key_version_path(key_name=key_name)
    sign_response = client.asymmetric_sign(
        request={
            "name": key_version,
            "digest": {"sha256": tx_hash_bytes},
        }
    )
    return sign_response.signature


def get_public_key(key_name: str | None = None) -> bytes:
    """Return the uncompressed secp256k1 public key bytes for the given KMS key.

    Returns 65-byte uncompressed point (0x04 prefix + X + Y).
    """
    client = get_kms_client()
    key_version = _key_version_path(key_name=key_name)
    response = client.get_public_key(request={"name": key_version})
    pub_key = load_pem_public_key(response.pem.encode())
    return pub_key.public_bytes(Encoding.X962, PublicFormat.UncompressedPoint)
