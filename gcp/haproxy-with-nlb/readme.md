# Overview

This Terraform module creates a regional network load balancer (NLB) that targets a bank of 
HAProxies for public access to a Redpanda REST service (through the officially published Pandaproxy URL).

In contrast with the other approaches (`../haproxy` and `../neg`), this approach does not create an Identity Aware HTTPs
Proxy (IAP), but instead creates an NLB. The key differences are as follows:

- The NLB operates as a TCP passthrough
- There is no TLS termination at the LB level (or indeed at the HAProxy level)
- Mutual TLS (mTLS), whereby a client certificate is used to authenticate the client, is possible
- A private DNS zone is required to override the Redpanda supplied hostname to point at the IP address of the NLB

## Implementation

Customise `vars.tf` with details about your GCP environment and Redpanda cluster.

# Post-Install

Once the proxy is running, create a private DNS zone and entry (or a local /etc/hosts entry) that overrides the Redpanda 
supplied hostname with the IP address of the NLB.

