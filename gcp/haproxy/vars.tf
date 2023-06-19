# GCP Config

variable "project_name" {
  default = "xxxxxx"
}

variable "region" {
  default = "europe-west1"
}

variable "availability_zones" {
  default     = ["b", "c", "d"]
  type        = list(string)
}

# Redpanda Config

variable "pandaproxy" {
  default = "pandaproxy-xxxxxx.byoc.prd.cloud.redpanda.com:30082"
}

variable "rp-network" {
  default = "projects/xxxxxx/global/networks/redpanda-xxxxxx"
}

# IAP Proxy Config

variable "iap-proxy-fqdn" {
  default = "proxy.xxxxxx.com"
}

variable "oauth2_client_id" {
  default = "xxxxxx.apps.googleusercontent.com"
}

variable "oauth2_client_secret" {
  default = "xxxxxx"
}

# HAProxy VM Config

variable "proxy-count" {
  default = 3
}

variable "proxy-vpc-cidr" {
  default = "192.168.10.0/24"
}

variable "image" {
  default = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "public_key_path" {
  default = "xxxxxx/id_rsa.pub"
}

variable "ssh_user" {
  default = "xxxxxx"
}
