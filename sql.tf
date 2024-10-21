resource "google_compute_global_address" "private_ip_address_data_pizza" {
  provider = google-beta

  name          = "${var.DATA_PIZZA_DEPLOYMENT}-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.network_data_pizza.id
}
resource "google_sql_database_instance" "instance_data_pizza" {
  provider = google-beta
  deletion_protection = "false"
  name             = "${var.SQL_NAME}-${random_id.db_name_suffix.hex}"
  region           = var.GCP_REGION
  database_version = "POSTGRES_15"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.network_data_pizza.self_link
      enable_private_path_for_google_cloud_services = true
    }
  }
}
resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.network_data_pizza.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address_data_pizza.name]
}
resource "random_id" "db_name_suffix" {
  byte_length = 4
}
resource "google_sql_database" "database_data_pizza" {
  name     = "${var.SQL_NAME}_database"
  instance = google_sql_database_instance.instance_data_pizza.name
}
resource "google_sql_user" "db_user" {
  name     = var.CLOUD_DB_USERNAME
  instance = google_sql_database_instance.instance_data_pizza.name
  password = var.CLOUD_DB_PASSWORD
}
