output "member_treasury_key_id" {
  value = google_kms_crypto_key.member_treasury.id
}

output "affiliate_treasury_key_id" {
  value = google_kms_crypto_key.affiliate_treasury.id
}

output "wholesale_treasury_key_id" {
  value = google_kms_crypto_key.wholesale_treasury.id
}
