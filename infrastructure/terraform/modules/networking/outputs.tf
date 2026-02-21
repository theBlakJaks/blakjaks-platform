output "network_self_link" {
  value = google_compute_network.blakjaks.self_link
}

output "subnetwork_self_link" {
  value = google_compute_subnetwork.primary.self_link
}

output "ingress_ip" {
  value = google_compute_global_address.ingress.address
}
