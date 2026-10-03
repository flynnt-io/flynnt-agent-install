#!/bin/bash

# $1 is the k3s config
# $2 is the k8s version
install_k3s() {
  k3s_configuration=$1
  k8s_version=$2
  configure_inotify_limits
  download_configure_and_start_k3s "$k3s_configuration" "$k8s_version"
}

# Every container shim holds inotify instances against the host root user's
# limit, so the default of 128 runs out at around 50 pods.
configure_inotify_limits() {
  printf '%b' "fs.inotify.max_user_instances = 8192\nfs.inotify.max_user_watches = 524288\n" > /etc/sysctl.d/90-flynnt-inotify.conf
  sysctl -q -p /etc/sysctl.d/90-flynnt-inotify.conf
}

# $1 is the k3s config
# $2 is the k8s version
download_configure_and_start_k3s() {
  k3s_configuration=$1
  k8s_version=$2
  mkdir -p /etc/systemd/system/k3s.service.d/
  write_private_file /etc/systemd/system/k3s.service.d/flynnt.conf "$k3s_configuration"
  export INSTALL_K3S_VERSION=v$k8s_version+k3s1
  curl -sfL https://get.k3s.io | sh - 1> /dev/null
}