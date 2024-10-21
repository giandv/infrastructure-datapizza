provider "google" {
  project                     = var.PROJECT_ID
  region                      = var.GCP_REGION
  credentials                 = "./terraform-impersonate.json"
  impersonate_service_account = var.IMPERSONATE_USER
}
provider "google-beta" {
  project                     = var.PROJECT_ID
  region                      = var.GCP_REGION
  credentials                 = "./terraform-impersonate.json"
  impersonate_service_account = var.IMPERSONATE_USER
}
data "google_project" "project" {}
