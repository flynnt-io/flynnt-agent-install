#!/bin/bash

remove_wireguard() {
  # Units may already be gone after a partial install or an earlier remove.
  systemctl disable --now "wg-quick@flynnt-wg" "wireguard_reresolve-dns.timer" || true
  systemctl stop "wireguard_reresolve-dns.service" || true

  rm -f /etc/wireguard/flynnt-wg.conf
  rm -f /etc/sysctl.d/flynnt.conf
  rm -f /etc/systemd/system/wireguard_reresolve-dns.timer
  rm -f /etc/systemd/system/wireguard_reresolve-dns.service
  rm -rf /opt/flynnt
  systemctl daemon-reload

  if systemctl is-active --quiet "wg-quick@flynnt-wg"; then
    die "WireGuard failed to uninstall properly."
  fi
  echo "WireGuard uninstalled successfully."
}
