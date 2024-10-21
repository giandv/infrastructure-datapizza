resource "google_compute_network" "network_data_pizza" {
  name                    = "${var.NETWORK_NAME}"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
  lifecycle {
    prevent_destroy = false
  }
}
resource "google_compute_subnetwork" "subnetwork_data_pizza" {
  name          = "${var.SUBNETWORK_NAME}"
  ip_cidr_range = "10.10.0.0/16"
  network       = google_compute_network.network_data_pizza.id
  region        = var.GCP_REGION
  private_ip_google_access = true
}
