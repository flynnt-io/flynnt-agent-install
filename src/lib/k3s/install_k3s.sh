#!/bin/bash

# $1 is the k3s config
# $2 is the k8s version
install_k3s() {
  k3s_configuration=$1
  k8s_version=$2
  download_configure_and_start_k3s "$k3s_configuration" "$k8s_version"
}

# $1 is the k3s config
# $2 is the k8s version
download_configure_and_start_k3s() {
  k3s_configuration=$1
  k8s_version=$2
  mkdir -p /etc/systemd/system/k3s.service.d/
  printf '%b' "$k3s_configuration" > /etc/systemd/system/k3s.service.d/flynnt.conf
  export INSTALL_K3S_VERSION=v$k8s_version+k3s1
  curl -sfL https://get.k3s.io | sh - 1> /dev/null
}