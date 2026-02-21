output "gke_cluster_endpoint" {
  value = module.gke.cluster_endpoint
}

output "cloudsql_connection_name" {
  value = module.cloudsql.connection_name
}

output "cloudsql_private_ip" {
  value = module.cloudsql.private_ip
}

output "redis_host" {
  value = module.redis.host
}

output "artifact_registry_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/blakjaks-repo"
}

output "ingress_ip" {
  value = module.networking.ingress_ip
}

output "kms_member_treasury_key_id" {
  value = module.kms.member_treasury_key_id
}

output "kms_affiliate_treasury_key_id" {
  value = module.kms.affiliate_treasury_key_id
}

output "kms_wholesale_treasury_key_id" {
  value = module.kms.wholesale_treasury_key_id
}
