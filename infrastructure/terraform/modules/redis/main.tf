resource "google_redis_instance" "cache" {
  name                    = var.instance_name
  tier                    = var.environment == "production" ? "STANDARD_HA" : "BASIC"
  memory_size_gb          = var.environment == "production" ? 4 : 1
  region                  = var.region
  authorized_network      = var.network
  connect_mode            = "PRIVATE_SERVICE_ACCESS"
  redis_version           = "REDIS_7_0"
  auth_enabled            = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  reserved_ip_range       = "10.0.16.0/29"
  labels                  = { environment = var.environment }
}
