#!/usr/bin/env bash
set -Eeuo pipefail
R='\033[0;31m';G='\033[0;32m';C='\033[0;36m';Y='\033[1;33m';N='\033[0m'
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
run(){ if [[ -n "$DIR" && -f "$DIR/$1" ]]; then bash "$DIR/$1"; else echo -e "${R}Host the whole scripts folder, then run again.${N}"; fi; }
banner(){ clear; echo -e "${R}██╗  ██╗ █████╗ ██████╗ ████████╗██╗██╗  ██╗${N}"; echo -e "${C}KartikExtras Installer Portal${N}"; echo "--------------------------------------------"; }
while true; do banner
echo -e "${Y}1.${N} VPS Optimizer"
echo -e "${Y}2.${N} Docker Installer"
echo -e "${Y}3.${N} Pterodactyl Panel/Wings Menu"
echo -e "${Y}4.${N} Pterodactyl Theme Manager"
echo -e "${Y}5.${N} Full Setup: Optimize + Docker + Pterodactyl Menu"
echo -e "${Y}6.${N} Server Info"
echo -e "${Y}7.${N} Exit"
read -rp "Choose option: " o
case "$o" in
1) run optimizer.sh;; 2) run docker.sh;; 3) run pterodactyl.sh;; 4) run theme-manager.sh;;
5) run optimizer.sh; run docker.sh; run pterodactyl.sh;;
6) grep PRETTY_NAME /etc/os-release; uname -r; free -h; df -h /;;
7) exit 0;; *) echo "Invalid";;
esac
read -rp "Press Enter..."
done
