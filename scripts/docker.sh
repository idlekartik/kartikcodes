#!/usr/bin/env bash
set -Eeuo pipefail
R='\033[0;31m';G='\033[0;32m';C='\033[0;36m';N='\033[0m'
[[ $EUID -eq 0 ]] || { echo -e "${R}Run as root.${N}"; exit 1; }
echo -e "${C}Installing Docker using official Docker convenience script...${N}"
apt-get update -y
apt-get install -y curl ca-certificates gnupg
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker
apt-get install -y docker-compose-plugin || true
ufw allow 8080/tcp || true
ufw allow 2022/tcp || true
ufw allow 25565/tcp || true
ufw allow 25565/udp || true
docker --version || true
docker compose version || true
echo -e "${G}Docker install complete.${N}"
