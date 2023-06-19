# GCP Config

variable "project_name" {
  default = "xxxxxx"
}

variable "region" {
  default = "us-west2"
}

# Redpanda Config

variable "network_endpoint_groups" {
  default = [
    "projects/xxxxxx/zones/europe-west1-b/networkEndpointGroups/k8s1-xxxxxx",
    "projects/xxxxxx/zones/europe-west1-c/networkEndpointGroups/k8s1-xxxxxx",
    "projects/xxxxxx/zones/europe-west1-d/networkEndpointGroups/k8s1-xxxxxx"
  ]
}

variable "rp-network" {
  default = "redpanda-xxxxxx"
}

# IAP Proxy Config

variable "iap-proxy-fqdn" {
  default = "proxy.xxxxxx.net"
}

variable "oauth2_client_id" {
  default = "xxxxxx.apps.googleusercontent.com"
}

variable "oauth2_client_secret" {
  default = "xxxxxx"
}