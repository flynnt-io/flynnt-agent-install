#!/bin/bash

# This is taken from https://github.com/WireGuard/wireguard-tools/blob/master/contrib/reresolve-dns/reresolve-dns.sh
reresolvedns_script() {
  cat <<'EOF'
#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (C) 2015-2020 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.

set -e
shopt -s nocasematch
shopt -s extglob
export LC_ALL=C

CONFIG_FILE="$1"
[[ $CONFIG_FILE =~ ^[a-zA-Z0-9_=+.-]{1,15}$ ]] && CONFIG_FILE="/etc/wireguard/$CONFIG_FILE.conf"
[[ $CONFIG_FILE =~ /?([a-zA-Z0-9_=+.-]{1,15})\.conf$ ]]
INTERFACE="${BASH_REMATCH[1]}"

process_peer() {
	[[ $PEER_SECTION -ne 1 || -z $PUBLIC_KEY || -z $ENDPOINT ]] && return 0
	[[ $(wg show "$INTERFACE" latest-handshakes) =~ ${PUBLIC_KEY//+/\\+}[[:blank:]]*([0-9]+) ]] || return 0
	(( ($EPOCHSECONDS - ${BASH_REMATCH[1]}) > 60 )) || return 0
	wg set "$INTERFACE" peer "$PUBLIC_KEY" endpoint "$ENDPOINT"
	reset_peer_section
}

reset_peer_section() {
	PEER_SECTION=0
	PUBLIC_KEY=""
	ENDPOINT=""
}

reset_peer_section
while read -r line || [[ -n $line ]]; do
	stripped="${line%%\#*}"
	key="${stripped%%=*}"; key="${key##*([[:space:]])}"; key="${key%%*([[:space:]])}"
	value="${stripped#*=}"; value="${value##*([[:space:]])}"; value="${value%%*([[:space:]])}"
	[[ $key == "["* ]] && { process_peer; reset_peer_section; }
	[[ $key == "[Peer]" ]] && PEER_SECTION=1
	if [[ $PEER_SECTION -eq 1 ]]; then
		case "$key" in
		PublicKey) PUBLIC_KEY="$value"; continue ;;
		Endpoint) ENDPOINT="$value"; continue ;;
		esac
	fi
done < "$CONFIG_FILE"
process_peer
EOF
}

# Services from: https://wiki.archlinux.org/title/WireGuard
reresolvedns_timer() {
  cat <<'EOF'
[Unit]
Description=Periodically reresolve DNS of Flynnt WireGuard Endpoint

[Timer]
OnCalendar=*:*:0/30

[Install]
WantedBy=timers.target
EOF
}

reresolvedns_service() {
  cat <<'EOF'
[Unit]
Description=Reresolve DNS of Flynnt WireGuard Endpoint
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c '/opt/flynnt/reresolve-dns.sh /etc/wireguard/flynnt-wg.conf'
EOF
}

