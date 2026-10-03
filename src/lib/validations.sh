#!/bin/bash

# Both rules also keep the names safe to use in API paths and JSON bodies.

# Kubernetes node names are DNS subdomains.
validate_dns_subdomain() {
  local label='[a-z0-9]([-a-z0-9]*[a-z0-9])?'
  [[ ${#1} -le 253 && $1 =~ ^$label(\.$label)*$ ]] || echo "must consist of lowercase letters, digits, '-' and '.', start and end with a letter or digit, and be at most 253 characters long"
}

# Cluster names are used as a single label in the cluster's hostname.
validate_dns_label() {
  [[ $1 =~ ^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$ ]] || echo "must consist of lowercase letters, digits and '-', start and end with a letter or digit, and be at most 63 characters long"
}
