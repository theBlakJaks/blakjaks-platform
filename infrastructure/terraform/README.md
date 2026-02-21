# BlakJaks Infrastructure — Terraform

Provisions the GCP resources required to run BlakJaks in staging and production.

## Prerequisites

- [Terraform >= 1.6](https://developer.hashicorp.com/terraform/downloads)
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) authenticated to `blakjaks-production`
- GCP project `blakjaks-production` with billing enabled

## One-time: Create Terraform state bucket

Run once before the first `terraform init`:

```bash
gsutil mb -l us-central1 gs://blakjaks-terraform-state
gsutil versioning set on gs://blakjaks-terraform-state
```

## Init + Apply

### Staging

```bash
cd infrastructure/terraform
terraform init
terraform apply -var-file=environments/staging.tfvars -var="db_password=YOUR_PASSWORD"
```

### Production

```bash
terraform apply -var-file=environments/production.tfvars -var="db_password=YOUR_PASSWORD"
```

> Alternatively: `export TF_VAR_db_password=YOUR_PASSWORD` and omit the `-var` flag.

## After `terraform apply`

### 1. Get cluster credentials

```bash
gcloud container clusters get-credentials blakjaks-primary --region us-central1
```

### 2. Apply Kubernetes manifests

```bash
kubectl apply -f ../k8s/namespaces.yaml
kubectl apply -f ../k8s/staging/
kubectl apply -f ../k8s/base/
```

### 3. Bootstrap secrets

```bash
cd ../../
./scripts/bootstrap_secrets.sh
```

Fill in real values at:
https://console.cloud.google.com/security/secret-manager?project=blakjaks-production

Then create the K8s secret:
```bash
kubectl create secret generic blakjaks-secrets \
  --from-literal=DATABASE_URL="postgres://..." \
  --from-literal=SECRET_KEY="..." \
  --from-literal=REDIS_URL="redis://..." \
  # ... all other keys from bootstrap_secrets.sh
  -n staging
```

### 4. Deploy

```bash
git push origin staging   # triggers GitHub Actions CI/CD pipeline
```

## Important Notes

- **KMS keys** have `prevent_destroy = true` — cannot be accidentally deleted via Terraform
- **`db_password`** is never stored in `.tfvars` — always pass via `-var` flag or `TF_VAR_db_password`
- **CloudSQL deletion protection** is enabled for production — `terraform destroy` will not delete the DB
- **`BLOCKCHAIN_DEV_PRIVATE_KEY`** in the staging K8s secret enables testnet USDC transfers without KMS; omit from production

## Module Summary

| Module | Purpose |
|--------|---------|
| `networking` | VPC, subnet, NAT, static IP, VPC peering for private services |
| `gke` | GKE cluster + api-pool + worker-pool (Workload Identity enabled) |
| `cloudsql` | PostgreSQL 15, private IP, SSL required, automated backups |
| `redis` | Redis 7.0, HA in prod, auth + TLS enabled |
| `kms` | 3 secp256k1 signing keys for treasury wallets (member/affiliate/wholesale) |
| `gcs` | 7 storage buckets (documents, QR codes, avatars, HLS, backups, etc.) |
