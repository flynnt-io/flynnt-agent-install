#!/bin/bash

## Most of this is taken from https://github.com/angristan/wireguard-install and adapted to our needs

# $1 is the wireguard config
install_wireguard() {
  export DEBIAN_FRONTEND=noninteractive
  wireguard_configuration=$1
  check_if_running_in_virtualization
  check_os_version
  install_wireguard_package
  configure_and_start_wireguard "$wireguard_configuration"
}

check_if_running_in_virtualization() {
  if [ "$(systemd-detect-virt)" == "openvz" ]; then
    echo "OpenVZ is not supported at this time"
    exit 1
  fi

  if [ "$(systemd-detect-virt)" == "lxc" ]; then
    echo "LXC is not supported (yet)."
    echo "WireGuard can technically run in an LXC container,"
    echo "but the kernel module has to be installed on the host,"
    echo "the container has to be run with some specific parameters"
    echo "and only the tools need to be installed in the container."
    exit 1
  fi
  if grep -qi microsoft /proc/version; then
    echo "WSL is not supported at this time"
    exit 1
  fi
}

check_os_version() {
	if [[ -e /etc/debian_version ]]; then
	  # shellcheck source=/dev/null
		source /etc/os-release
		OS="${ID}" # debian or ubuntu
		if [[ ${ID} == "debian" || ${ID} == "raspbian" ]]; then
			if [[ ${VERSION_ID} -lt 10 ]]; then
				echo "Your version of Debian (${VERSION_ID}) is not supported. Please use Debian 10 Buster or later"
				exit 1
			fi
			OS=debian # overwrite if raspbian
		fi
	elif [[ -e /etc/fedora-release ]]; then
	  # shellcheck source=/dev/null
		source /etc/os-release
		OS="${ID}"
	elif [[ -e /etc/centos-release ]]; then
	  # shellcheck source=/dev/null
		source /etc/os-release
		OS=centos
	elif [[ -e /etc/oracle-release ]]; then
	  # shellcheck source=/dev/null
		source /etc/os-release
		OS=oracle
	elif [[ -e /etc/arch-release ]]; then
		OS=arch
	else
		echo "Looks like you aren't running this on a Debian, Ubuntu, Fedora, CentOS, Oracle or Arch Linux system"
		exit 1
	fi
}

install_wireguard_package() {
	# Install WireGuard from package repository
	if [[ ${OS} == 'ubuntu' ]] || [[ ${OS} == 'debian' && ${VERSION_ID} -gt 10 ]]; then
		apt-get -qqq update
		apt-get -qqq install -y wireguard iptables resolvconf > /dev/null
	elif [[ ${OS} == 'debian' ]]; then
		if ! grep -rqs "^deb .* buster-backports" /etc/apt/; then
			echo "deb http://deb.debian.org/debian buster-backports main" >/etc/apt/sources.list.d/backports.list
			apt-get -qqq update
		fi
		apt -qqq update
		apt-get -qqq install -y iptables resolvconf > /dev/null
		apt-get -qqq install -y -t buster-backports wireguard > /dev/null
	elif [[ ${OS} == 'fedora' ]]; then
		if [[ ${VERSION_ID} -lt 32 ]]; then
			dnf install -y dnf-plugins-core
			dnf copr enable -y jdoss/wireguard
			dnf install -y wireguard-dkms
		fi
		dnf install -y wireguard-tools iptables
	elif [[ ${OS} == 'centos' ]]; then
		yum -y install epel-release elrepo-release
		if [[ ${VERSION_ID} -eq 7 ]]; then
			yum -y install yum-plugin-elrepo
		fi
		yum -y install kmod-wireguard wireguard-tools iptables
	elif [[ ${OS} == 'oracle' ]]; then
		dnf install -y oraclelinux-developer-release-el8
		dnf config-manager --disable -y ol8_developer
		dnf config-manager --enable -y ol8_developer_UEKR6
		dnf config-manager --save -y --setopt=ol8_developer_UEKR6.includepkgs='wireguard-tools*'
		dnf install -y wireguard-tools iptables
	elif [[ ${OS} == 'arch' ]]; then
		pacman -S --needed --noconfirm wireguard-tools
	fi
	# Make sure the directory exists (this does not seem the be the case on fedora)
	mkdir -p /etc/wireguard
	chmod 600 -R /etc/wireguard/
}

# $1 is the wireguard config
configure_and_start_wireguard() {
  wireguardConfig=$1
  # Enable routing on the server
  printf '%b' "net.ipv4.ip_forward = 1\nnet.ipv6.conf.all.forwarding = 1" >/etc/sysctl.d/flynnt.conf
  printf '%b' "$wireguardConfig" > /etc/wireguard/flynnt-wg.conf
  sysctl -q --system
  systemctl start "wg-quick@flynnt-wg.service"
  systemctl enable "wg-quick@flynnt-wg.service"

  # Check if WireGuard is running
  systemctl is-active --quiet "wg-quick@flynnt-wg.service"
  WG_RUNNING=$?
  # WireGuard might not work if we updated the kernel. Tell the user to reboot
  if [[ ${WG_RUNNING} -ne 0 ]]; then
    echo -e "\n$(red WARNING: WireGuard does not seem to be running.)"
    echo -e "You can check if WireGuard is running with: systemctl status wg-quick@flynnt-wg"
    echo -e "If you get something like \"Cannot find device flynnt-wg\", please reboot!"
  fi
}