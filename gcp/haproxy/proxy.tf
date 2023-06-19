resource "google_compute_network" "proxy-network" {
  name = "${var.prefix}-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "proxy-network-subnet" {
  name = "${var.prefix}-subnet"
  ip_cidr_range = var.proxy-vpc-cidr
  region = var.region
  network = google_compute_network.proxy-network.id
}

resource "google_compute_router" "router" {
  project = var.project_name
  name    = "${var.prefix}-router"
  network = google_compute_network.proxy-network.id
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.prefix}-router-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.proxy-network-subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_global_address" "iap-public-ip" {
  name = "${var.prefix}-public-ip"
}

resource "google_compute_managed_ssl_certificate" "iap-proxy" {
  name = "${var.prefix}-certificate"
  managed {
    domains = [var.iap-proxy-fqdn]
  }
}

resource "google_compute_instance" "haproxy" {
  machine_type = "n1-standard-1"
  count = var.proxy-count
  name = "${var.prefix}-vm-${count.index}"
  zone = "${var.region}-${var.availability_zones[count.index % length(var.availability_zones)]}"
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
  name = "${var.prefix}-instance-group-${var.region}-${var.availability_zones[count.index]}"
  count = length(var.availability_zones)
  zone = "${var.region}-${var.availability_zones[count.index]}"
  instances = tolist([for i in google_compute_instance.haproxy.* : i.self_link if i.zone == "${var.region}-${var.availability_zones[count.index]}"])
  named_port {
    name = "https"
    port = 443
  }
}

resource "google_compute_network_peering" "peering1" {
  name         = "${var.prefix}-peering-inbound"
  network      = google_compute_network.proxy-network.self_link
  peer_network = var.rp-network
}

resource "google_compute_network_peering" "peering2" {
  name         = "${var.prefix}-peering-outbound"
  network      = var.rp-network
  peer_network = google_compute_network.proxy-network.self_link
}

resource "google_compute_health_check" "default" {
  name = "${var.prefix}-health-check"
  tcp_health_check {
    port = 443
  }
}

resource "google_compute_firewall" "default" {
  name    = "${var.prefix}-health-check-firewall-rule"
  network = google_compute_network.proxy-network.name
  allow {
    protocol = "all"
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # These are the Google Health Check sources
  direction = "INGRESS"
  priority = 1
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_backend_service" "default" {
  name = "${var.prefix}-backend-service"
  protocol = "HTTPS"
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
  name            = "${var.prefix}-urlmap"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_https_proxy" "default" {
  name             = "${var.prefix}-https-proxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.iap-proxy.id]
  url_map          = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name = "${var.prefix}-global-forwarding-rule"
  target = google_compute_target_https_proxy.default.id
  ip_protocol = "TCP"
  port_range = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address = google_compute_global_address.iap-public-ip.id
}

