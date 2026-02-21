provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "certificatemanager.googleapis.com",
    "translate.googleapis.com",
    "servicenetworking.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

module "networking" {
  source     = "./modules/networking"
  project_id = var.project_id
  region     = var.region
}

module "gke" {
  source       = "./modules/gke"
  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  cluster_name = var.gke_cluster_name
  network      = module.networking.network_self_link
  subnetwork   = module.networking.subnetwork_self_link
}

module "cloudsql" {
  source        = "./modules/cloudsql"
  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  instance_name = var.db_instance_name
  db_name       = var.db_name
  db_user       = var.db_user
  db_password   = var.db_password
  network       = module.networking.network_self_link
  depends_on    = [module.networking]
}

module "redis" {
  source        = "./modules/redis"
  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  instance_name = var.redis_instance_name
  network       = module.networking.network_self_link
}

module "gcs" {
  source     = "./modules/gcs"
  project_id = var.project_id
  region     = var.region
}

module "kms" {
  source                        = "./modules/kms"
  project_id                    = var.project_id
  region                        = var.region
  backend_service_account_email = google_service_account.backend.email
}

# Artifact Registry
resource "google_artifact_registry_repository" "blakjaks" {
  repository_id = "blakjaks-repo"
  format        = "DOCKER"
  location      = var.region
  depends_on    = [google_project_service.apis]
}

# GitHub Actions Workload Identity — must match deploy.yml exactly
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  depends_on                = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  oidc { issuer_uri = "https://token.actions.githubusercontent.com" }
  attribute_condition = "assertion.repository == '${var.github_repo}'"
}

# GitHub Actions service account — matches deploy.yml
resource "google_service_account" "github_actions" {
  account_id   = "blakjaks-service-account"
  display_name = "BlakJaks GitHub Actions"
}

resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset([
    "roles/container.developer",
    "roles/artifactregistry.writer",
    "roles/storage.objectViewer",
    "roles/secretmanager.secretAccessor",
    "roles/iam.serviceAccountTokenCreator",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_service_account_iam_binding" "github_workload_identity" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
  ]
}

# Backend pod service account (GKE Workload Identity)
resource "google_service_account" "backend" {
  account_id   = "blakjaks-backend"
  display_name = "BlakJaks Backend Pod"
}

resource "google_project_iam_member" "backend_roles" {
  for_each = toset([
    "roles/secretmanager.secretAccessor",
    "roles/storage.objectAdmin",
    "roles/cloudsql.client",
    "roles/cloudkms.signerVerifier",
    "roles/cloudtranslate.user",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.backend.email}"
}

resource "google_service_account_iam_binding" "backend_workload_identity" {
  service_account_id = google_service_account.backend.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[staging/backend-ksa]",
    "serviceAccount:${var.project_id}.svc.id.goog[production/backend-ksa]",
  ]
}
