#!/usr/bin/env bash
set -Eeuo pipefail
R='\033[0;31m';G='\033[0;32m';C='\033[0;36m';Y='\033[1;33m';N='\033[0m'
[[ $EUID -eq 0 ]] || { echo -e "${R}Run as root.${N}"; exit 1; }
clear
echo -e "${R}KartikExtras Pterodactyl Menu${N}"
echo "1) Launch community auto-installer menu"
echo "2) Install/verify Docker for Wings"
echo "3) Create Pterodactyl directories"
echo "4) Open common firewall ports"
echo "5) Show docs links"
echo "6) Exit"
read -rp "Choose option: " o
case "$o" in
1)
 echo -e "${Y}This runs an unofficial community installer from GitHub. Continue only if you trust/review it.${N}"
 read -rp "Type YES to continue: " c
 [[ "$c" == "YES" ]] && bash <(curl -s https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer/master/install.sh) || echo "Cancelled."
 ;;
2) curl -fsSL https://get.docker.com | sh; systemctl enable --now docker; docker --version;;
3) mkdir -p /etc/pterodactyl /var/lib/pterodactyl /var/log/pterodactyl; echo -e "${G}Done.${N}";;
4) ufw allow 80/tcp || true; ufw allow 443/tcp || true; ufw allow 8080/tcp || true; ufw allow 2022/tcp || true; ufw allow 25565/tcp || true; ufw allow 25565/udp || true; echo -e "${G}Ports added.${N}";;
5) echo "Panel docs: https://pterodactyl.io/panel/1.0/getting_started.html"; echo "Wings docs: https://pterodactyl.io/wings/1.0/installing.html"; echo "Wings quickstart: https://pterodactyl-wings.mintlify.app/quickstart";;
6) exit 0;;
*) echo "Invalid";;
esac
