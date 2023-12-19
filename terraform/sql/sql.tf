# Create SQL Database Instance in VPC2.
resource "google_compute_global_address" "private_ip_address" {
  name          = "sql-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = var.vpc2_self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc2_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "sql_instance" {
  name             = "devops-sql"
  database_version = "POSTGRES_13"
  project          = var.project
  region           = var.region
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = true
      private_network                               = var.vpc2_self_link
      enable_private_path_for_google_cloud_services = true
    }
  }
  depends_on = [google_service_networking_connection.private_vpc_connection]
}
