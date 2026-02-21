resource "google_kms_key_ring" "treasury" {
  name     = "treasury-keys"
  location = var.region
}

# EC_SIGN_SECP256K1_SHA256 = Ethereum/Polygon compatible signing
resource "google_kms_crypto_key" "member_treasury" {
  name     = "member-treasury-key"
  key_ring = google_kms_key_ring.treasury.id
  purpose  = "ASYMMETRIC_SIGN"
  version_template {
    algorithm = "EC_SIGN_SECP256K1_SHA256"
  }
  lifecycle { prevent_destroy = true }
}

resource "google_kms_crypto_key" "affiliate_treasury" {
  name     = "affiliate-treasury-key"
  key_ring = google_kms_key_ring.treasury.id
  purpose  = "ASYMMETRIC_SIGN"
  version_template {
    algorithm = "EC_SIGN_SECP256K1_SHA256"
  }
  lifecycle { prevent_destroy = true }
}

resource "google_kms_crypto_key" "wholesale_treasury" {
  name     = "wholesale-treasury-key"
  key_ring = google_kms_key_ring.treasury.id
  purpose  = "ASYMMETRIC_SIGN"
  version_template {
    algorithm = "EC_SIGN_SECP256K1_SHA256"
  }
  lifecycle { prevent_destroy = true }
}

resource "google_kms_crypto_key_iam_member" "backend_member" {
  crypto_key_id = google_kms_crypto_key.member_treasury.id
  role          = "roles/cloudkms.signerVerifier"
  member        = "serviceAccount:${var.backend_service_account_email}"
}

resource "google_kms_crypto_key_iam_member" "backend_affiliate" {
  crypto_key_id = google_kms_crypto_key.affiliate_treasury.id
  role          = "roles/cloudkms.signerVerifier"
  member        = "serviceAccount:${var.backend_service_account_email}"
}

resource "google_kms_crypto_key_iam_member" "backend_wholesale" {
  crypto_key_id = google_kms_crypto_key.wholesale_treasury.id
  role          = "roles/cloudkms.signerVerifier"
  member        = "serviceAccount:${var.backend_service_account_email}"
}
