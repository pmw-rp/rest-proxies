# GCP Config

variable "prefix" {
  default = "rp-rest-haproxy-nlb"
}

variable "project_name" {
  default = "xxxxxx"
}

variable "region" {
  default = "us-central1"
}

variable "availability_zones" {
  default     = ["a", "b", "c"]
  type        = list(string)
}

# Redpanda Config

variable "pandaproxy" {
  default = "rp-xxxxxxx.data.vectorized.cloud:30291"
}

# HAProxy VM Config

variable "proxy-count" {
  default = 1
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

# NLB Access Config

variable "allowed_cidrs" {
  default = []
  type    = list(string)
}