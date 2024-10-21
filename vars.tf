variable "APP_SECURE_PORT" {
  type        = string
  # Related docker image
  description = "App secure port"
  default     = "9091"
}
variable "CLOUD_DB_PASSWORD" {
  type        = string
  description = "Postgress user password"
}
variable "CLOUD_DB_USERNAME" {
  type        = string
  description = "Postgress username"
}
variable "DATA_PIZZA_DEPLOYMENT" {
  type        = string
  description = "The name of this particular deployment for data pizza instance group."
}
variable "DNS" {
  description   = "The GCP DNS name"
  type          = string
}
variable "DNS_NAME" {
  description   = "The GCP DNS url"
  type          = string
}
variable "GCP_REGION" {
  description = "The GCP region where your instance groups will be released"
  type        = string
}
variable "GCP_ZONE" {
  description = "The GCP zone where your instance groups will be released"
  type        = string
}
variable "IMPERSONATE_USER" {
  description   = "Service account impersonation used for deploy on GCP platform"
  type          = string
}
variable "MACHINE_TYPE" {
  description = "The GCP machine type used for your instance groups"
  type        = string
}
variable "NETWORK_NAME"{
  description   = "Network name assigned to VPC"
  type          = string
}
variable "PROJECT_ID" {
  description = "The GCP project id where your instance groups will be released"
  type        = string
}
variable "SUB_DNS" {
  description   = "The GCP DNS name"
  type          = string
}
variable "SQL_NAME"{
  description   = "SQL instance name"
  type          = string
}
variable "SUBNETWORK_NAME"{
  description   = "Sub-network name assigned to VPC"
  type          = string
}
