"""Tests for the centralized KMS service.

All tests mock the KMS client — no real GCP calls are made.
"""

from unittest.mock import MagicMock, patch

import pytest

import app.services.kms_service as kms_module
from app.services.kms_service import get_kms_client, get_public_key, sign_transaction


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_fake_pem() -> str:
    """Return a minimal but structurally valid PEM-wrapped public key for tests.

    We generate a real ephemeral secp256k1 key so that load_pem_public_key
    actually succeeds without needing cryptography mocks.
    """
    from cryptography.hazmat.primitives.asymmetric.ec import (
        SECP256K1,
        generate_private_key,
    )
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives.serialization import (
        Encoding,
        PublicFormat,
    )

    private_key = generate_private_key(SECP256K1(), default_backend())
    pub_key = private_key.public_key()
    pem_bytes = pub_key.public_bytes(Encoding.PEM, PublicFormat.SubjectPublicKeyInfo)
    return pem_bytes.decode()


# ---------------------------------------------------------------------------
# Singleton / get_kms_client
# ---------------------------------------------------------------------------


def test_get_kms_client_returns_singleton():
    """get_kms_client() should return the same instance on repeated calls."""
    kms_module._kms_client = None  # reset singleton before test

    with patch("app.services.kms_service.kms.KeyManagementServiceClient") as mock_cls:
        fake_client = MagicMock()
        mock_cls.return_value = fake_client

        first = get_kms_client()
        second = get_kms_client()

    assert first is second
    assert mock_cls.call_count == 1  # constructor called exactly once
    kms_module._kms_client = None  # clean up


def test_get_kms_client_caches_across_calls():
    """Once initialized, subsequent calls must not re-instantiate the client."""
    kms_module._kms_client = None

    with patch("app.services.kms_service.kms.KeyManagementServiceClient") as mock_cls:
        mock_cls.return_value = MagicMock()
        get_kms_client()
        get_kms_client()
        get_kms_client()

    assert mock_cls.call_count == 1
    kms_module._kms_client = None


# ---------------------------------------------------------------------------
# sign_transaction
# ---------------------------------------------------------------------------


def test_sign_transaction_returns_bytes():
    """sign_transaction should return bytes of nonzero length."""
    kms_module._kms_client = None
    fake_der = b"\x30\x44" + b"\xab" * 68  # plausible DER blob

    mock_client = MagicMock()
    mock_response = MagicMock()
    mock_response.signature = fake_der
    mock_client.asymmetric_sign.return_value = mock_response

    with patch("app.services.kms_service.kms.KeyManagementServiceClient", return_value=mock_client):
        result = sign_transaction(b"\x00" * 32)

    assert isinstance(result, bytes)
    assert len(result) > 0
    assert result == fake_der
    kms_module._kms_client = None


def test_sign_transaction_passes_hash_to_client():
    """The digest sent to asymmetric_sign must contain the supplied tx_hash_bytes."""
    kms_module._kms_client = None
    tx_hash = b"\xde\xad" * 16  # 32 bytes

    mock_client = MagicMock()
    mock_client.asymmetric_sign.return_value = MagicMock(signature=b"\x01\x02\x03")

    with patch("app.services.kms_service.kms.KeyManagementServiceClient", return_value=mock_client):
        sign_transaction(tx_hash_bytes=tx_hash)

    call_kwargs = mock_client.asymmetric_sign.call_args
    request = call_kwargs.kwargs.get("request") or call_kwargs.args[0]
    assert request["digest"]["sha256"] == tx_hash
    kms_module._kms_client = None


def test_sign_transaction_uses_custom_key_name():
    """Passing key_name should embed that name in the KMS resource path."""
    kms_module._kms_client = None

    mock_client = MagicMock()
    mock_client.asymmetric_sign.return_value = MagicMock(signature=b"\xaa\xbb")

    with patch("app.services.kms_service.kms.KeyManagementServiceClient", return_value=mock_client):
        sign_transaction(b"\x00" * 32, key_name="affiliate-pool-signer")

    call_kwargs = mock_client.asymmetric_sign.call_args
    request = call_kwargs.kwargs.get("request") or call_kwargs.args[0]
    assert "affiliate-pool-signer" in request["name"]
    kms_module._kms_client = None


# ---------------------------------------------------------------------------
# get_public_key
# ---------------------------------------------------------------------------


def test_get_public_key_returns_65_bytes():
    """get_public_key should return exactly 65 bytes starting with 0x04."""
    kms_module._kms_client = None
    fake_pem = _make_fake_pem()

    mock_client = MagicMock()
    mock_client.get_public_key.return_value = MagicMock(pem=fake_pem)

    with patch("app.services.kms_service.kms.KeyManagementServiceClient", return_value=mock_client):
        result = get_public_key()

    assert isinstance(result, bytes)
    assert len(result) == 65
    assert result[0] == 0x04
    kms_module._kms_client = None


def test_get_public_key_starts_with_uncompressed_prefix():
    """The 0x04 prefix marks an uncompressed secp256k1 point."""
    kms_module._kms_client = None
    fake_pem = _make_fake_pem()

    mock_client = MagicMock()
    mock_client.get_public_key.return_value = MagicMock(pem=fake_pem)

    with patch("app.services.kms_service.kms.KeyManagementServiceClient", return_value=mock_client):
        result = get_public_key()

    assert result[0] == 0x04, "First byte must be 0x04 (uncompressed point prefix)"
    kms_module._kms_client = None


def test_get_public_key_uses_custom_key_name():
    """Passing key_name should embed that name in the KMS resource path."""
    kms_module._kms_client = None
    fake_pem = _make_fake_pem()

    mock_client = MagicMock()
    mock_client.get_public_key.return_value = MagicMock(pem=fake_pem)

    with patch("app.services.kms_service.kms.KeyManagementServiceClient", return_value=mock_client):
        get_public_key(key_name="wholesale-pool-signer")

    call_kwargs = mock_client.get_public_key.call_args
    request = call_kwargs.kwargs.get("request") or call_kwargs.args[0]
    assert "wholesale-pool-signer" in request["name"]
    kms_module._kms_client = None


# ---------------------------------------------------------------------------
# _key_version_path (internal helper)
# ---------------------------------------------------------------------------


def test_key_version_path_uses_config_defaults():
    """_key_version_path with no args should embed all config values."""
    from app.services.kms_service import _key_version_path
    from app.core.config import settings

    path = _key_version_path()
    assert settings.KMS_PROJECT_ID in path
    assert settings.KMS_LOCATION in path
    assert settings.KMS_KEYRING in path
    assert settings.KMS_KEY_NAME in path
    assert f"/cryptoKeyVersions/{settings.KMS_KEY_VERSION}" in path


def test_key_version_path_overrides_are_applied():
    """Explicit args to _key_version_path should override config defaults."""
    from app.services.kms_service import _key_version_path

    path = _key_version_path(
        project_id="my-project",
        location="europe-west1",
        key_ring="my-ring",
        key_name="my-key",
        version=3,
    )
    assert "my-project" in path
    assert "europe-west1" in path
    assert "my-ring" in path
    assert "my-key" in path
    assert path.endswith("/cryptoKeyVersions/3")
