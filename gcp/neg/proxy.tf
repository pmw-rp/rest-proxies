resource "google_compute_health_check" "default" {
  name = "${var.prefix}-health-check"
  tcp_health_check {
    port = 30082
  }
}

resource "google_compute_firewall" "default" {
  name    = "${var.prefix}-health-check-firewall-rule"
  network = var.rp-network
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

resource "google_compute_global_address" "default" {
  name = "${var.prefix}-public-ip"
}

resource "google_compute_managed_ssl_certificate" "default" {
  name = "${var.prefix}-certificate"
  managed {
    domains = [var.iap-proxy-fqdn]
  }
}

resource "google_compute_backend_service" "default" {
  name = "${var.prefix}-backend-service"
  protocol = "HTTPS"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  session_affinity = "CLIENT_IP"
  locality_lb_policy = "MAGLEV"
  enable_cdn = false
  dynamic "backend" {
    for_each = var.network_endpoint_groups
    content {
      group = backend.value
      balancing_mode = "RATE"
      max_rate = 100
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
  description     = "a description"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_https_proxy" "default" {
  name             = "${var.prefix}-https-proxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
  url_map          = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name = "${var.prefix}-global-forwarding-rule"
  target = google_compute_target_https_proxy.default.id
  ip_protocol = "TCP"
  port_range = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address = google_compute_global_address.default.id
}


