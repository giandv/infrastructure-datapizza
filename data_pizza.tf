module "data-pizza-lb-https" {
  # https://github.com/terraform-google-modules/terraform-google-lb-http/tree/master
  firewall_networks               = [google_compute_network.network_data_pizza.id]
  https_redirect                  = true
  managed_ssl_certificate_domains = ["${var.SUB_DNS}.${var.DNS}"]
  name                            = "${var.DATA_PIZZA_DEPLOYMENT}-lb"
  project                         = var.PROJECT_ID
  source                          = "GoogleCloudPlatform/lb-http/google"
  ssl                             = true
  version                         = "~> 12.0"

  backends = {
    default = {
      enable_cdn       = false
      port             = "${var.APP_SECURE_PORT}"
      port_name        = "https"
      protocol         = "HTTPS"
      session_affinity = "CLIENT_IP"
      timeout_sec      = 10

      groups = [
        {
          group = google_compute_instance_group_manager.compute_instance_group_manager_data_pizza.instance_group
        }
      ]
      health_check = {
        request_path = "/"
        port         = "${var.APP_SECURE_PORT}"
        name         = "${var.DATA_PIZZA_DEPLOYMENT}-health-chk"
        logging      = null
      }
      iap_config = {
        enable = false
      }
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
    }
  }
}

resource "google_compute_autoscaler" "compute_autoscaler_data_pizza" {
  autoscaling_policy {
    max_replicas    = 1# 30
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.25
    }
  }
  name    = "${var.DATA_PIZZA_DEPLOYMENT}-autoscaler"
  project = var.PROJECT_ID
  target  = google_compute_instance_group_manager.compute_instance_group_manager_data_pizza.id
  zone    = var.GCP_ZONE
}

resource "google_compute_firewall" "firewall_data_pizza" {
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["${var.APP_SECURE_PORT}"]
  }
  name          = "${var.DATA_PIZZA_DEPLOYMENT}-firewall"
  network       = google_compute_network.network_data_pizza.name
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_health_check" "compute_health_check_data_pizza" {
  check_interval_sec = 5

  healthy_threshold = 2
  http_health_check {
    request_path = "/"
    port         = var.APP_SECURE_PORT
  }

  name                = "${var.DATA_PIZZA_DEPLOYMENT}-autohealing-health-check"
  project             = var.PROJECT_ID
  timeout_sec         = 5
  unhealthy_threshold = 10 # 50 seconds
}

# Create Instance Template
resource "google_compute_instance_template" "compute_instance_template_data_pizza" {
  can_ip_forward = false

  description = "This template is used to create data pizza instances."
  disk {
    auto_delete  = true
    boot         = true
    disk_type    = "pd-standard"
    disk_size_gb = 40
    source_image = "ubuntu-os-cloud/ubuntu-2004-focal-v20220712"
  }

  instance_description = "${var.DATA_PIZZA_DEPLOYMENT} deployment"

  labels = { "${var.DATA_PIZZA_DEPLOYMENT}" = true }

  machine_type = var.MACHINE_TYPE

  name = "${var.DATA_PIZZA_DEPLOYMENT}-template-${random_string.random.id}"
  network_interface {
    subnetwork         = google_compute_subnetwork.subnetwork_data_pizza.self_link
    subnetwork_project = var.PROJECT_ID
  }

  project = var.PROJECT_ID

  service_account {
    email  = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/compute"]
  }

  tags = ["http-server", "private-ssh"]

  metadata_startup_script = <<EOF
sudo apt-get update -y
sudo snap install docker
export POSTGRES_USER=${var.CLOUD_DB_USERNAME}
export POSTGRES_PASSWORD=${var.CLOUD_DB_PASSWORD}
export POSTGRES_DATABASE=${var.SQL_NAME}
git clone https://github.com/giandv/back-end-datapizza.git
cd back-end-datapizza
CHECK_DATABASE=$(psql -U postgres -c '\l' | grep datapizza | wc -l)
if [[ "$CHECK_DATABASE" -eq "0" ]] ; then
  envsubst < ./database.tpl > ./database.sql
  \i ./database.sql
fi
envsubst < ./docker-compose.tpl > ./docker-compose.yml
sudo docker-compose up --build -d
sudo ufw allow 8000;
EOF

}

# Create Managed Instance Group
resource "google_compute_instance_group_manager" "compute_instance_group_manager_data_pizza" {
  all_instances_config {
    labels = { "${var.DATA_PIZZA_DEPLOYMENT}" = true }
  }
  auto_healing_policies {
    health_check      = google_compute_health_check.compute_health_check_data_pizza.id
    initial_delay_sec = 300
  }

  base_instance_name = "${var.DATA_PIZZA_DEPLOYMENT}-mig-${random_string.random.id}"

  lifecycle {
    create_before_destroy = true
  }

  name = "${var.DATA_PIZZA_DEPLOYMENT}-mig-${random_string.random.id}"
  named_port {
    name = "https"
    port = var.APP_SECURE_PORT
  }

  project  = var.PROJECT_ID
  provider = google-beta

  target_pools = [google_compute_target_pool.compute_target_pool_data_pizza.id]
  target_size  = 1

  version {
    instance_template = google_compute_instance_template.compute_instance_template_data_pizza.id
  }

  zone = var.GCP_ZONE

}

resource "google_compute_target_pool" "compute_target_pool_data_pizza" {
  name    = "${var.DATA_PIZZA_DEPLOYMENT}-target-pool"
  project = var.PROJECT_ID
  region  = var.GCP_REGION
}

resource "google_dns_record_set" "dns_record_set_data_pizza" {
  name         = "${var.SUB_DNS}.${var.DNS}."
  type         = "A"
  ttl          = 300
  #managed_zone = google_dns_managed_zone.data_pizza_dns_managed_zone.name
  managed_zone = var.DNS_NAME
  rrdatas      = [module.data-pizza-lb-https.external_ip]
}

resource "random_string" "random" {
  keepers = {
    first = "${timestamp()}"
  }
  length  = 4
  special = false
  upper   = false
}
