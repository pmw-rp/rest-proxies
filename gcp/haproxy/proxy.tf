resource "random_uuid" "deployment" {}

# Deployment Management Resources

locals {
  uuid          = random_uuid.deployment.result
  deployment_id = random_uuid.deployment.result
}

resource "google_compute_network" "proxy-network" {
  name = "tf-vpc-proxy-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "proxy-network-subnet" {
  name = "tf-vpc-proxy-subnet"
  ip_cidr_range = var.proxy-vpc-cidr
  region = var.region
  network = google_compute_network.proxy-network.id
}

## Create Cloud Router

resource "google_compute_router" "router" {
  project = var.project_name
  name    = "tf-nat-router"
  network = google_compute_network.proxy-network.id
  region  = var.region
}

## Create Nat Gateway

resource "google_compute_router_nat" "nat" {
  name                               = "tf-router-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_global_address" "iap-public-ip" {
  name = "tf-iap-public-ip"
}

resource "google_compute_managed_ssl_certificate" "iap-proxy" {
  name = "tf-iap-certificate"

  managed {
    domains = [var.iap-proxy-fqdn]
  }
}

resource "google_compute_instance" "haproxy" {
  machine_type = "n1-standard-1"
  count = var.proxy-count
  name = "haproxy-${count.index}"
  zone = "${var.region}-${var.availability_zones[count.index % length(var.availability_zones)]}"
  hostname = "haproxy-${count.index}.nuln.net"

    metadata = {
    ssh-keys = <<KEYS
${var.ssh_user}:${file(abspath(var.public_key_path))}
KEYS
  }

  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.proxy-network-subnet.name
  }

  metadata_startup_script = templatefile("${path.module}/startup.tftpl", { pandaproxy = var.pandaproxy })
}

resource "google_compute_instance_group" "haproxies" {
  name = "tf-haproxy-instance-group"
  count = length(var.availability_zones)
  zone = "${var.region}-${var.availability_zones[count.index]}"
  instances = tolist([for i in google_compute_instance.haproxy.* : i.self_link if i.zone == "${var.region}-${var.availability_zones[count.index]}"])
  named_port {
    name = "https"  # Here
    port = 443 # Here
  }
}

resource "google_compute_network_peering" "peering1" {
  name         = "tf-peering-1"
  network      = google_compute_network.proxy-network.self_link
  peer_network = var.rp-network
}

resource "google_compute_network_peering" "peering2" {
  name         = "tf-peering-2"
  network      = var.rp-network
  peer_network = google_compute_network.proxy-network.self_link
}

# Health Check Resources

resource "google_compute_health_check" "default" {
  name = "tf-hap-hc"
  tcp_health_check {
    port = 443 # Here
  }
}

resource "google_compute_firewall" "default" {
  name    = "tf-hap-hc-fw-allow2"
  network = google_compute_network.proxy-network.name
  allow {
    protocol = "all"
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  direction = "INGRESS"
  priority = 1
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_backend_service" "default" {
  name = "tf-hap-backend-service"
  protocol = "HTTPS" # Here
  load_balancing_scheme = "EXTERNAL_MANAGED"
  session_affinity = "CLIENT_IP"
  locality_lb_policy = "MAGLEV"
  enable_cdn = false
  port_name = "https"

  dynamic "backend" {
    for_each = google_compute_instance_group.haproxies
    content {
      group          = backend.value.self_link
      balancing_mode = "RATE"
      max_rate       = 100
    }
  }

  log_config {
    enable = true
    sample_rate = 1
  }
  health_checks = [google_compute_health_check.default.id]
  iap {
    oauth2_client_id     = var.oauth2_client_id
    oauth2_client_secret = var.oauth2_client_secret
  }
}

resource "google_compute_url_map" "default" {
  name            = "tf-hap-urlmap"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_https_proxy" "default" {
  name             = "tf-hap-https-proxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.iap-proxy.id]
  url_map          = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name = "tf-hap-global-forwarding-rule"
  target = google_compute_target_https_proxy.default.id
  ip_protocol = "TCP"
  port_range = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address = google_compute_global_address.iap-public-ip.id
}

