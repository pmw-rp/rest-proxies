# Overview

This Terraform module creates an IAP protected, GCP native HTTPs load balancer for public access
to a Redpanda REST service through GCP Network Endpoint Groups.

## Implementation

Customise `vars.tf` with details about your GCP environment and Redpanda cluster.

# Post-Install

Once the proxy is running, create an external DNS entry that points the proxy FQDN (defined in `iap-proxy-fqdn`)
to the external IP address of the proxy, given as an output. After a period of time, the certificate
should be valid.

