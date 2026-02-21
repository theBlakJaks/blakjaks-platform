#!/usr/bin/env bash
# bootstrap.sh — One-time GCP setup for BlakJaks CI/CD pipeline.
#
# Run this once from a terminal authenticated as a project Owner/Editor:
#
#   gcloud auth login
#   gcloud config set project blakjaks-production
#   bash infrastructure/bootstrap.sh
#
# What this does:
#   1. Enables required GCP APIs
#   2. Creates the Artifact Registry repository for Docker images
#   3. Creates the GitHub Actions service account and grants it the roles
#      defined in infrastructure/terraform/main.tf
#   4. Creates the Workload Identity pool + OIDC provider so GitHub Actions
#      can authenticate via OIDC (no long-lived keys needed)
#   5. Binds the WIF principal to the service account
#
# After running this script the CI pipeline will be able to push Docker images
# to Artifact Registry. Full infrastructure (GKE, Cloud SQL, Redis, KMS, etc.)
# must still be provisioned via `terraform apply`.

set -euo pipefail

PROJECT_ID="blakjaks-production"
PROJECT_NUMBER="752012521116"
REGION="us-central1"
GITHUB_REPO="theBlakJaks/blakjaks-platform"

CI_SA_NAME="blakjaks-service-account"
CI_SA_EMAIL="${CI_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

WIF_POOL="github-pool"
WIF_PROVIDER="github-provider"

REGISTRY_NAME="blakjaks-repo"

echo "==> Enabling required GCP APIs..."
gcloud services enable \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  container.googleapis.com \
  secretmanager.googleapis.com \
  --project="${PROJECT_ID}"

echo "==> Creating Artifact Registry repository (${REGISTRY_NAME})..."
if ! gcloud artifacts repositories describe "${REGISTRY_NAME}" \
     --location="${REGION}" --project="${PROJECT_ID}" &>/dev/null; then
  gcloud artifacts repositories create "${REGISTRY_NAME}" \
    --repository-format=docker \
    --location="${REGION}" \
    --project="${PROJECT_ID}"
  echo "    Created ${REGISTRY_NAME}."
else
  echo "    Already exists — skipping."
fi

echo "==> Creating GitHub Actions service account (${CI_SA_NAME})..."
if ! gcloud iam service-accounts describe "${CI_SA_EMAIL}" \
     --project="${PROJECT_ID}" &>/dev/null; then
  gcloud iam service-accounts create "${CI_SA_NAME}" \
    --display-name="BlakJaks GitHub Actions" \
    --project="${PROJECT_ID}"
  echo "    Created ${CI_SA_EMAIL}."
else
  echo "    Already exists — skipping."
fi

echo "==> Granting project-level IAM roles to CI service account..."
for ROLE in \
  "roles/artifactregistry.writer" \
  "roles/container.developer" \
  "roles/storage.objectViewer" \
  "roles/secretmanager.secretAccessor" \
  "roles/iam.serviceAccountTokenCreator"
do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${CI_SA_EMAIL}" \
    --role="${ROLE}" \
    --condition=None \
    --quiet
  echo "    Granted ${ROLE}."
done

echo "==> Creating Workload Identity pool (${WIF_POOL})..."
if ! gcloud iam workload-identity-pools describe "${WIF_POOL}" \
     --location=global --project="${PROJECT_ID}" &>/dev/null; then
  gcloud iam workload-identity-pools create "${WIF_POOL}" \
    --location=global \
    --display-name="GitHub Actions pool" \
    --project="${PROJECT_ID}"
  echo "    Created ${WIF_POOL}."
else
  echo "    Already exists — skipping."
fi

echo "==> Creating Workload Identity OIDC provider (${WIF_PROVIDER})..."
if ! gcloud iam workload-identity-pools providers describe "${WIF_PROVIDER}" \
     --workload-identity-pool="${WIF_POOL}" \
     --location=global --project="${PROJECT_ID}" &>/dev/null; then
  gcloud iam workload-identity-pools providers create-oidc "${WIF_PROVIDER}" \
    --location=global \
    --workload-identity-pool="${WIF_POOL}" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
    --attribute-condition="assertion.repository == '${GITHUB_REPO}'" \
    --project="${PROJECT_ID}"
  echo "    Created ${WIF_PROVIDER}."
else
  echo "    Already exists — skipping."
fi

echo "==> Binding Workload Identity principal to CI service account..."
WIF_PRINCIPAL="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WIF_POOL}/attribute.repository/${GITHUB_REPO}"
gcloud iam service-accounts add-iam-policy-binding "${CI_SA_EMAIL}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="${WIF_PRINCIPAL}" \
  --project="${PROJECT_ID}" \
  --quiet
echo "    Bound ${WIF_PRINCIPAL}."

echo ""
echo "✓ Bootstrap complete. GitHub Actions can now authenticate and push"
echo "  Docker images to: ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REGISTRY_NAME}"
echo ""
echo "Next step: run Terraform to provision GKE, Cloud SQL, Redis, KMS, etc."
echo "  cd infrastructure/terraform"
echo "  terraform init -backend-config='bucket=blakjaks-terraform-state'"
echo "  terraform apply -var-file=environments/production.tfvars"
