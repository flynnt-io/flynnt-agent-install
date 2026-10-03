#!/bin/bash

# shellcheck disable=SC2154
if [[ -z ${args[--yes]:-} ]]; then
  echo ""
  # Read from the terminal, as stdin is the script itself when piped from curl.
  read -rp "Do you really want to remove this node from the cluster? [y/n]: " -e REMOVE < /dev/tty \
    || die "No terminal available to confirm the removal. Use --yes to skip the prompt."
  if [[ ${REMOVE:-n} != 'y' ]]; then
    echo ""
    echo "Removal aborted!"
    exit 0
  fi
fi

remove_wireguard
remove_k3s

# Reapplies values that other files on the host configure. Values that only the
# removed flynnt files set stay in effect until the next reboot.
sysctl -q --system || true
