#!/usr/bin/env bash
set -Eeuo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
MAGENTA="\033[0;35m"
NC="\033[0m"

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo -e "${RED}Run as root. Example: sudo bash install.sh${NC}"
    echo -e "${YELLOW}If using curl command, login as root first or use:${NC}"
    echo "sudo bash -c 'bash <(curl -s YOUR_LINK)'"
    exit 1
  fi
}

banner() {
  clear
  echo -e "${RED}"
  cat <<'BANNER'
██╗  ██╗ █████╗ ██████╗ ████████╗██╗██╗  ██╗
██║ ██╔╝██╔══██╗██╔══██╗╚══██╔══╝██║██║ ██╔╝
█████╔╝ ███████║██████╔╝   ██║   ██║█████╔╝
██╔═██╗ ██╔══██║██╔══██╗   ██║   ██║██╔═██╗
██║  ██╗██║  ██║██║  ██║   ██║   ██║██║  ██╗
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝╚═╝  ╚═╝
BANNER
  echo -e "${NC}${CYAN}KartikExtras Installer Portal${NC}"
  echo -e "${YELLOW}Single-file installer • No missing script errors${NC}"
  echo "------------------------------------------------------------"
}

pause() {
  echo
  read -rp "Press Enter..."
}

server_info() {
  echo -e "${CYAN}Server Info${NC}"
  echo "OS: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo Unknown)"
  echo "Kernel: $(uname -r)"
  echo "CPU Cores: $(nproc)"
  echo "RAM:"
  free -h || true
  echo "Disk:"
  df -h / || true
  echo "IP:"
  hostname -I || true
}

vps_optimizer() {
  need_root
  echo -e "${CYAN}Starting VPS Optimizer...${NC}"
  export DEBIAN_FRONTEND=noninteractive

  echo -e "${YELLOW}[1/9] apt update${NC}"
  apt-get update -y

  echo -e "${YELLOW}[2/9] apt upgrade${NC}"
  apt-get upgrade -y

  echo -e "${YELLOW}[3/9] Installing useful packages${NC}"
  apt-get install -y curl wget git unzip zip tar htop nano vim ufw ca-certificates gnupg lsb-release software-properties-common net-tools dnsutils jq screen tmux cron logrotate build-essential

  echo -e "${YELLOW}[4/9] Cleaning system${NC}"
  apt-get autoremove -y
  apt-get autoclean -y

  echo -e "${YELLOW}[5/9] Applying sysctl optimization${NC}"
  cat >/etc/sysctl.d/99-kartikextras.conf <<'EOF'
vm.swappiness=10
vm.vfs_cache_pressure=50
fs.file-max=2097152
net.core.somaxconn=65535
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_tw_reuse=1
net.ipv4.ip_forward=1
net.ipv4.tcp_max_syn_backlog=65535
net.core.netdev_max_backlog=16384
EOF
  sysctl --system || true

  echo -e "${YELLOW}[6/9] Setting file limits${NC}"
  cat >/etc/security/limits.d/99-kartikextras.conf <<'EOF'
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

  echo -e "${YELLOW}[7/9] Swap check/setup${NC}"
  if ! swapon --show | grep -q "/swapfile"; then
    RAM_MB=$(free -m | awk '/Mem:/ {print $2}')
    if [[ "${RAM_MB:-0}" -lt 4096 ]]; then
      fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
      echo -e "${GREEN}2GB swap created.${NC}"
    else
      echo -e "${CYAN}RAM >= 4GB, swap skipped.${NC}"
    fi
  else
    echo -e "${CYAN}Swap already exists.${NC}"
  fi

  echo -e "${YELLOW}[8/9] Firewall common ports${NC}"
  ufw allow OpenSSH || true
  ufw allow 22/tcp || true
  ufw allow 80/tcp || true
  ufw allow 443/tcp || true
  ufw allow 8080/tcp || true
  ufw allow 2022/tcp || true
  ufw allow 25565/tcp || true
  ufw allow 25565/udp || true

  echo -e "${YELLOW}[9/9] Final check${NC}"
  apt-get autoremove -y
  echo -e "${GREEN}VPS Optimizer complete. Reboot recommended after major upgrades.${NC}"
}

install_docker() {
  need_root
  echo -e "${CYAN}Installing Docker...${NC}"
  apt-get update -y
  apt-get install -y curl ca-certificates gnupg lsb-release
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
  apt-get install -y docker-compose-plugin || true
  echo -e "${GREEN}Docker installed.${NC}"
  docker --version || true
  docker compose version || true
  docker ps || true

  ufw allow 8080/tcp || true
  ufw allow 2022/tcp || true
  ufw allow 25565/tcp || true
  ufw allow 25565/udp || true
}

install_java() {
  need_root
  echo -e "${CYAN}Installing Java 21...${NC}"
  apt-get update -y
  apt-get install -y openjdk-21-jdk
  java -version
}

install_node() {
  need_root
  echo -e "${CYAN}Installing Node.js 20...${NC}"
  apt-get update -y
  apt-get install -y curl
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
  node -v
  npm -v
}

minecraft_server_setup() {
  need_root
  echo -e "${CYAN}Setting up Minecraft server folder...${NC}"
  apt-get update -y
  apt-get install -y openjdk-21-jdk wget screen curl
  mkdir -p /home/minecraft
  cd /home/minecraft
  cat > start.sh <<'EOF'
#!/usr/bin/env bash
java -Xms1G -Xmx2G -jar server.jar nogui
EOF
  chmod +x start.sh
  echo "eula=true" > eula.txt
  ufw allow 25565/tcp || true
  ufw allow 25565/udp || true
  echo -e "${GREEN}Minecraft folder ready: /home/minecraft${NC}"
  echo -e "${YELLOW}Put your server.jar in /home/minecraft, then run: ./start.sh${NC}"
}

pterodactyl_menu() {
  need_root
  while true; do
    clear
    echo -e "${RED}KartikExtras Pterodactyl Panel/Wings Menu${NC}"
    echo "------------------------------------------------------------"
    echo -e "${YELLOW}1.${NC} Install dependencies for Pterodactyl Panel"
    echo -e "${YELLOW}2.${NC} Install Docker for Wings"
    echo -e "${YELLOW}3.${NC} Open Pterodactyl/Wings ports"
    echo -e "${YELLOW}4.${NC} Create Pterodactyl directories"
    echo -e "${YELLOW}5.${NC} Launch community auto-installer"
    echo -e "${YELLOW}6.${NC} Show official docs"
    echo -e "${YELLOW}7.${NC} Back"
    echo "------------------------------------------------------------"
    read -rp "Choose option: " p

    case "$p" in
      1)
        apt-get update -y
        apt-get install -y curl wget git unzip zip tar software-properties-common ca-certificates apt-transport-https gnupg lsb-release nginx redis-server mariadb-server php php-cli php-gd php-mysql php-mbstring php-bcmath php-xml php-curl php-zip php-fpm php-intl
        echo -e "${GREEN}Panel dependencies installed.${NC}"
        pause
        ;;
      2)
        install_docker
        pause
        ;;
      3)
        ufw allow 80/tcp || true
        ufw allow 443/tcp || true
        ufw allow 8080/tcp || true
        ufw allow 2022/tcp || true
        ufw allow 25565/tcp || true
        ufw allow 25565/udp || true
        echo -e "${GREEN}Ports opened.${NC}"
        pause
        ;;
      4)
        mkdir -p /etc/pterodactyl /var/lib/pterodactyl /var/log/pterodactyl /var/www/pterodactyl
        echo -e "${GREEN}Directories created.${NC}"
        pause
        ;;
      5)
        echo -e "${YELLOW}This runs an unofficial community installer from GitHub.${NC}"
        echo -e "${YELLOW}Use only if you trust/review it. Continue?${NC}"
        read -rp "Type YES to continue: " confirm
        if [[ "$confirm" == "YES" ]]; then
          bash <(curl -s https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer/master/install.sh)
        else
          echo "Cancelled."
        fi
        pause
        ;;
      6)
        echo "Panel docs: https://pterodactyl.io/panel/1.0/getting_started.html"
        echo "Wings docs: https://pterodactyl.io/wings/1.0/installing.html"
        echo "Wings quickstart: https://pterodactyl-wings.mintlify.app/quickstart"
        pause
        ;;
      7) return ;;
      *) echo "Invalid"; pause ;;
    esac
  done
}

theme_manager() {
  need_root
  PANEL_DIR="${PANEL_DIR:-/var/www/pterodactyl}"
  BACKUP_DIR="/root/kartikextras-theme-backups"

  backup_panel() {
    mkdir -p "$BACKUP_DIR"
    if [[ ! -d "$PANEL_DIR" ]]; then
      echo -e "${RED}Panel directory not found: $PANEL_DIR${NC}"
      echo "Set custom path example:"
      echo "PANEL_DIR=/var/www/pterodactyl bash install.sh"
      return 1
    fi
    tar -czf "$BACKUP_DIR/panel-$(date +%F-%H%M%S).tar.gz" -C "$(dirname "$PANEL_DIR")" "$(basename "$PANEL_DIR")"
    echo -e "${GREEN}Backup saved in $BACKUP_DIR${NC}"
  }

  while true; do
    clear
    echo -e "${RED}KartikExtras Pterodactyl Theme Manager${NC}"
    echo "------------------------------------------------------------"
    echo -e "${YELLOW}1.${NC} Backup current panel"
    echo -e "${YELLOW}2.${NC} Prepare theme from ZIP URL"
    echo -e "${YELLOW}3.${NC} Prepare theme from local ZIP"
    echo -e "${YELLOW}4.${NC} Back"
    echo "------------------------------------------------------------"
    echo -e "${CYAN}Safe mode: backup + extract/review. It will not blindly overwrite panel files.${NC}"
    read -rp "Choose option: " t

    case "$t" in
      1)
        backup_panel
        pause
        ;;
      2)
        read -rp "Theme ZIP direct URL: " url
        [[ -z "$url" ]] && echo "No URL." && pause && continue
        backup_panel || true
        tmp="/tmp/kartik-theme-$$"
        mkdir -p "$tmp/theme"
        curl -L "$url" -o "$tmp/theme.zip"
        unzip -o "$tmp/theme.zip" -d "$tmp/theme"
        echo -e "${YELLOW}Theme extracted to: $tmp/theme${NC}"
        echo -e "${YELLOW}Review files before copying to: $PANEL_DIR${NC}"
        pause
        ;;
      3)
        read -rp "Local theme ZIP path: " zip_path
        [[ ! -f "$zip_path" ]] && echo "File not found." && pause && continue
        backup_panel || true
        tmp="/tmp/kartik-theme-$$"
        mkdir -p "$tmp/theme"
        unzip -o "$zip_path" -d "$tmp/theme"
        echo -e "${YELLOW}Theme extracted to: $tmp/theme${NC}"
        echo -e "${YELLOW}Review files before copying to: $PANEL_DIR${NC}"
        pause
        ;;
      4) return ;;
      *) echo "Invalid"; pause ;;
    esac
  done
}

full_setup() {
  vps_optimizer
  install_docker
  pterodactyl_menu
}

while true; do
  banner
  echo -e "${YELLOW}1.${NC} VPS Optimizer"
  echo -e "${YELLOW}2.${NC} Docker Installer"
  echo -e "${YELLOW}3.${NC} Java 21 Installer"
  echo -e "${YELLOW}4.${NC} Node.js 20 Installer"
  echo -e "${YELLOW}5.${NC} Minecraft Server Folder Setup"
  echo -e "${YELLOW}6.${NC} Pterodactyl Panel/Wings Menu"
  echo -e "${YELLOW}7.${NC} Pterodactyl Theme Manager"
  echo -e "${YELLOW}8.${NC} Full Setup: Optimize + Docker + Pterodactyl Menu"
  echo -e "${YELLOW}9.${NC} Server Info"
  echo -e "${YELLOW}10.${NC} Exit"
  echo "------------------------------------------------------------"
  read -rp "Choose option: " choice

  case "$choice" in
    1) vps_optimizer; pause ;;
    2) install_docker; pause ;;
    3) install_java; pause ;;
    4) install_node; pause ;;
    5) minecraft_server_setup; pause ;;
    6) pterodactyl_menu ;;
    7) theme_manager ;;
    8) full_setup; pause ;;
    9) server_info; pause ;;
    10) exit 0 ;;
    *) echo -e "${RED}Invalid option.${NC}"; pause ;;
  esac
done
