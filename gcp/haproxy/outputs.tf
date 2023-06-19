output "deployment" {
  value = local.deployment_id
}

output "iap-ip-address" {
  value = google_compute_global_address.iap-public-ip.address
}

#output "haproxy-ip-address" {
#  value = google_compute_instance.haproxy-vm.network_interface[0].network_ip
#}

#output "haproxy-public-address" {
#  value = google_compute_instance.haproxy-vm.network_interface[0].access_config[0].nat_ip
#}