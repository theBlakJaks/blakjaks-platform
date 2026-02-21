resource "google_container_cluster" "primary" {
  name                     = var.cluster_name
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = var.network
  subnetwork               = var.subnetwork

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  addons_config {
    horizontal_pod_autoscaling { disabled = false }
    http_load_balancing        { disabled = false }
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  }
}

# API node pool — backend, web-app, portals
resource "google_container_node_pool" "api" {
  name     = "api-pool"
  cluster  = google_container_cluster.primary.id
  location = var.region

  autoscaling {
    min_node_count = var.environment == "production" ? 2 : 1
    max_node_count = var.environment == "production" ? 10 : 3
  }

  node_config {
    machine_type = var.environment == "production" ? "n2-standard-4" : "e2-standard-2"
    disk_size_gb = 50
    disk_type    = "pd-ssd"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    workload_metadata_config { mode = "GKE_METADATA" }
    labels = {
      pool        = "api"
      environment = var.environment
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Worker node pool — Celery
resource "google_container_node_pool" "workers" {
  name     = "worker-pool"
  cluster  = google_container_cluster.primary.id
  location = var.region

  autoscaling {
    min_node_count = 1
    max_node_count = var.environment == "production" ? 5 : 2
  }

  node_config {
    machine_type = var.environment == "production" ? "n2-standard-2" : "e2-standard-2"
    disk_size_gb = 50
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    workload_metadata_config { mode = "GKE_METADATA" }
    labels = {
      pool        = "workers"
      environment = var.environment
    }
    taint {
      key    = "pool"
      value  = "workers"
      effect = "NO_SCHEDULE"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
