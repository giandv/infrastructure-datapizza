resource "google_dns_managed_zone" "data_pizza_dns_managed_zone" {
  name     = var.DNS_NAME
  dns_name = "${var.DNS}."
  dnssec_config {
    state = "off"
  }
}
