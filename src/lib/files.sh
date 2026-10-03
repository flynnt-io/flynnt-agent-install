#!/bin/bash

# For files holding the cluster join token or the WireGuard private key. The
# chmod also covers files left behind by earlier installs.
write_private_file() {
  local path=$1 content=$2
  (umask 077 && printf '%b' "$content" > "$path")
  chmod 600 "$path"
}
