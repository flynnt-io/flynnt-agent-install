#!/bin/bash

remove_wireguard() {
  systemctl stop "wg-quick@flynnt-wg"
  systemctl stop "wireguard_reresolve-dns.timer"
  systemctl stop "wireguard_reresolve-dns.service"
  systemctl disable "wg-quick@flynnt-wg"
  systemctl disable "wireguard_reresolve-dns.timer"
  systemctl disable "wireguard_reresolve-dns.service"

  rm -f /etc/wireguard/flynnt-wg.conf
  rm -f /etc/sysctl.d/flynnt.conf
  rm -rf /opt/flynnt
  # Reload sysctl
  sysctl --system
  # Reload systemd
  systemctl daemon-reload
  # Check if WireGuard is running
  systemctl is-active --quiet "wg-quick@flynnt-wg"
  WG_RUNNING=$?
  if [[ ${WG_RUNNING} -eq 0 ]]; then
    echo "WireGuard failed to uninstall properly."
    exit 1
  else
    echo "WireGuard uninstalled successfully."
    exit 0
  fi
}
