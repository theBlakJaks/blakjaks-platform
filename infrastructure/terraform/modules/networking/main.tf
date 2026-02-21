resource "google_compute_network" "blakjaks" {
  name                    = "blakjaks-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "primary" {
  name          = "blakjaks-primary-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.blakjaks.id
  secondary_ip_range { range_name = "pods";     ip_cidr_range = "10.48.0.0/14" }
  secondary_ip_range { range_name = "services"; ip_cidr_range = "10.52.0.0/20" }
  private_ip_google_access = true
}

resource "google_compute_router" "nat" {
  name    = "blakjaks-nat-router"
  network = google_compute_network.blakjaks.id
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "blakjaks-nat"
  router                             = google_compute_router.nat.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_global_address" "ingress" {
  name = "blakjaks-ingress-ip"
}

resource "google_compute_global_address" "private_services" {
  name          = "blakjaks-private-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.blakjaks.id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.blakjaks.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]
}
