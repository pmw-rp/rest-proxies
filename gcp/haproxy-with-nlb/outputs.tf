output "nlb-ip-address" {
  value = google_compute_address.nlb-public-ip.address
}