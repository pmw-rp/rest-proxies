output "deployment" {
  value = local.deployment_id
}

output "ip-address" {
  value = google_compute_global_address.default.address
}