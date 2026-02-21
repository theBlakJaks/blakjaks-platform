resource "google_sql_database_instance" "postgres" {
  name                = var.instance_name
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = var.environment == "production"

  settings {
    tier              = var.environment == "production" ? "db-n1-standard-4" : "db-g1-small"
    availability_type = var.environment == "production" ? "REGIONAL" : "ZONAL"
    disk_autoresize   = true
    disk_size         = var.environment == "production" ? 100 : 20
    disk_type         = "PD_SSD"

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = var.environment == "production"
      start_time                     = "03:00"
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network
      require_ssl     = true
    }

    database_flags {
      name  = "max_connections"
      value = var.environment == "production" ? "200" : "50"
    }
  }
}

resource "google_sql_database" "blakjaks" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "app" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}
