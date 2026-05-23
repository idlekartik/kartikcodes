#!/usr/bin/env bash
set -Eeuo pipefail
R='\033[0;31m';G='\033[0;32m';C='\033[0;36m';Y='\033[1;33m';N='\033[0m'
[[ $EUID -eq 0 ]] || { echo -e "${R}Run as root.${N}"; exit 1; }
export DEBIAN_FRONTEND=noninteractive
echo -e "${C}KartikExtras VPS Optimizer starting...${N}"
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget git unzip zip tar htop nano vim ufw ca-certificates gnupg lsb-release software-properties-common net-tools dnsutils jq screen tmux cron logrotate
apt-get autoremove -y
apt-get autoclean -y
cat >/etc/sysctl.d/99-kartikextras.conf <<'EOF'
vm.swappiness=10
vm.vfs_cache_pressure=50
fs.file-max=2097152
net.core.somaxconn=65535
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_tw_reuse=1
net.ipv4.ip_forward=1
EOF
sysctl --system || true
cat >/etc/security/limits.d/99-kartikextras.conf <<'EOF'
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF
if ! swapon --show | grep -q /swapfile; then
  RAM=$(free -m | awk '/Mem:/ {print $2}')
  if [[ "$RAM" -lt 4096 ]]; then
    fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
    grep -q /swapfile /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
  fi
fi
ufw allow OpenSSH || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw allow 8080/tcp || true
ufw allow 2022/tcp || true
echo -e "${G}VPS optimization complete. Reboot recommended after big upgrades.${N}"
