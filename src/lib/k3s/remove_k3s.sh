#!/bin/bash

remove_k3s() {
  /usr/local/bin/k3s-agent-uninstall.sh
  rm -r /etc/systemd/system/k3s.service.d/
  rm -f /etc/sysctl.d/90-flynnt-inotify.conf
}