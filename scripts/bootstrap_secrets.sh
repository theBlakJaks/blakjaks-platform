#!/bin/bash
# Creates all GCP Secret Manager secrets with REPLACE_ME placeholders.
# Run once after Terraform apply. Then fill in real values in GCP Console.
# Usage: ./scripts/bootstrap_secrets.sh

set -e
PROJECT_ID="blakjaks-production"

create_secret() {
  local name=$1
  if gcloud secrets describe "$name" --project="$PROJECT_ID" &>/dev/null; then
    echo "  EXISTS: $name"
  else
    echo "  CREATING: $name"
    echo -n "REPLACE_ME" | gcloud secrets create "$name" \
      --project="$PROJECT_ID" \
      --replication-policy="automatic" \
      --data-file=-
  fi
}

echo "Bootstrapping GCP Secret Manager for: $PROJECT_ID"
echo ""

echo "=== Database ==="
create_secret "DATABASE_URL"
create_secret "DATABASE_PASSWORD"

echo "=== Auth ==="
create_secret "SECRET_KEY"
create_secret "AUTH_JWT_PRIVATE_KEY"
create_secret "AUTH_JWT_PUBLIC_KEY"

echo "=== Redis ==="
create_secret "REDIS_URL"
create_secret "REDIS_PASSWORD"

echo "=== Blockchain ==="
create_secret "INFURA_PROJECT_ID"

echo "=== Dev Signing ==="
create_secret "BLOCKCHAIN_DEV_PRIVATE_KEY"
create_secret "BLOCKCHAIN_DEV_TREASURY_ADDRESS"

echo "=== Dwolla ==="
create_secret "DWOLLA_KEY"
create_secret "DWOLLA_SECRET"
create_secret "DWOLLA_WEBHOOK_SECRET"
create_secret "DWOLLA_MASTER_FUNDING_SOURCE_ID"

echo "=== Authorize.net ==="
create_secret "PAYMENT_AUTHORIZE_API_LOGIN_ID"
create_secret "PAYMENT_AUTHORIZE_TRANSACTION_KEY"
create_secret "PAYMENT_AUTHORIZE_CLIENT_KEY"
create_secret "PAYMENT_AUTHORIZE_SIGNATURE_KEY"

echo "=== Push Notifications ==="
create_secret "APNS_KEY_ID"
create_secret "APNS_TEAM_ID"
create_secret "APNS_KEY_PATH"
create_secret "FCM_SERVICE_ACCOUNT_JSON"

echo "=== Third-party APIs ==="
create_secret "OPENAI_API_KEY"
create_secret "GOOGLE_TRANSLATE_API_KEY"
create_secret "GIPHY_API_KEY"
create_secret "SENTRY_DSN"
create_secret "INTERCOM_APP_ID"
create_secret "INTERCOM_API_KEY"
create_secret "INTERCOM_IDENTITY_VERIFICATION_SECRET"
create_secret "TELLER_APPLICATION_ID"
create_secret "TELLER_WEBHOOK_SECRET"
create_secret "AGECHECKER_CLIENT_API_KEY"

echo ""
echo "Done. Fill in values at:"
echo "https://console.cloud.google.com/security/secret-manager?project=$PROJECT_ID"
