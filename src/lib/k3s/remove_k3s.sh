#!/bin/bash

remove_k3s() {
  # get.k3s.io runs without K3S_URL during install, so k3s is set up as
  # k3s.service with the server uninstall script, even though it runs as agent.
  if [[ -x /usr/local/bin/k3s-uninstall.sh ]]; then
    /usr/local/bin/k3s-uninstall.sh
  elif [[ -x /usr/local/bin/k3s-agent-uninstall.sh ]]; then
    /usr/local/bin/k3s-agent-uninstall.sh
  else
    echo "No k3s uninstall script found, skipping k3s removal."
  fi
  rm -rf /etc/systemd/system/k3s.service.d/
  rm -f /etc/sysctl.d/90-flynnt-inotify.conf
}
