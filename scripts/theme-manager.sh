#!/usr/bin/env bash
set -Eeuo pipefail
R='\033[0;31m';G='\033[0;32m';C='\033[0;36m';Y='\033[1;33m';N='\033[0m'
[[ $EUID -eq 0 ]] || { echo -e "${R}Run as root.${N}"; exit 1; }
PANEL_DIR="${PANEL_DIR:-/var/www/pterodactyl}"
BACKUP_DIR="/root/kartikextras-theme-backups"
backup(){ mkdir -p "$BACKUP_DIR"; [[ -d "$PANEL_DIR" ]] || { echo -e "${R}Panel not found: $PANEL_DIR${N}"; exit 1; }; tar -czf "$BACKUP_DIR/panel-$(date +%F-%H%M%S).tar.gz" -C "$(dirname "$PANEL_DIR")" "$(basename "$PANEL_DIR")"; echo -e "${G}Backup saved: $BACKUP_DIR${N}"; }
clear
echo -e "${R}KartikExtras Theme Manager${N}"
echo "1) Backup current panel"
echo "2) Prepare theme from ZIP URL"
echo "3) Prepare theme from local ZIP"
echo "4) Exit"
read -rp "Choose option: " o
case "$o" in
1) backup;;
2) read -rp "Theme ZIP URL: " u; backup; T="/tmp/kartik-theme-$$"; mkdir -p "$T"; curl -L "$u" -o "$T/theme.zip"; unzip -o "$T/theme.zip" -d "$T/theme"; echo -e "${Y}Extracted to $T/theme. Review files before copying to $PANEL_DIR.${N}";;
3) read -rp "Local ZIP path: " z; [[ -f "$z" ]] || { echo "Not found"; exit 1; }; backup; T="/tmp/kartik-theme-$$"; mkdir -p "$T/theme"; unzip -o "$z" -d "$T/theme"; echo -e "${Y}Extracted to $T/theme. Review files before copying.${N}";;
4) exit 0;;
*) echo "Invalid";;
esac
