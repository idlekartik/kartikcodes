#!/usr/bin/env bash
set -Eeuo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo -e "${RED}Run as root. Example: sudo bash install.sh${NC}"
    echo "bash <(curl -s https://idlekartik.github.io/kartikcodes/scripts/install.sh)"
    exit 1
  fi
}

pause() {
  echo
  read -rp "Press Enter..."
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
  echo -e "${YELLOW}Made by KartikExtras${NC}"
  echo "------------------------------------------------------------"
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

  echo -e "${YELLOW}[9/9] Final cleanup${NC}"
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
    echo -e "${YELLOW}Made by KartikExtras${NC}"
    echo "------------------------------------------------------------"
    echo -e "${YELLOW}1.${NC} Install dependencies for Pterodactyl Panel"
    echo -e "${YELLOW}2.${NC} Install Docker for Wings"
    echo -e "${YELLOW}3.${NC} Open Pterodactyl/Wings ports"
    echo -e "${YELLOW}4.${NC} Create Pterodactyl directories"
    echo -e "${YELLOW}5.${NC} Launch Panel/Wings auto-installer"
    echo -e "${YELLOW}6.${NC} Show docs links"
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
        echo -e "${YELLOW}This will run Panel/Wings auto-installer.${NC}"
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

blueprint_installer() {
  need_root
  clear
  echo -e "${RED}KartikExtras Blueprint Installer${NC}"
  echo -e "${YELLOW}Made by KartikExtras${NC}"
  echo "------------------------------------------------------------"
  echo "This will install Blueprint for Pterodactyl."
  echo "Command:"
  echo "bash <(curl -fsSL https://github.com/infinityForge-labs/blueprint-installer/raw/refs/heads/main/ultra-install.sh)"
  echo "------------------------------------------------------------"
  read -rp "Type YES to run Blueprint installer: " confirm
  if [[ "$confirm" == "YES" ]]; then
    bash <(curl -fsSL https://github.com/infinityForge-labs/blueprint-installer/raw/refs/heads/main/ultra-install.sh)
  else
    echo "Cancelled."
  fi
}

theme_app() {
  need_root
  clear
  echo -e "${RED}KartikExtras Theme Installer App${NC}"
  echo -e "${YELLOW}Made by KartikExtras${NC}"
  echo "------------------------------------------------------------"
  echo "This will run:"
  echo "bash <(curl -s https://ptero.jishnu.site)"
  echo "------------------------------------------------------------"
  read -rp "Type YES to run Theme Installer App: " confirm
  if [[ "$confirm" == "YES" ]]; then
    bash <(curl -s https://ptero.jishnu.site)
  else
    echo "Cancelled."
  fi
}

theme_installer() {
  need_root
  while true; do
    clear
    echo -e "${RED}KartikExtras Pterodactyl Theme Installer${NC}"
    echo -e "${YELLOW}Made by KartikExtras${NC}"
    echo "------------------------------------------------------------"
    echo -e "${YELLOW}1.${NC} Blueprint Installer for Pterodactyl"
    echo -e "${YELLOW}2.${NC} Theme Names / Theme Installer App"
    echo -e "${YELLOW}3.${NC} Back"
    echo "------------------------------------------------------------"
    read -rp "Choose option: " t

    case "$t" in
      1) blueprint_installer; pause ;;
      2) theme_app; pause ;;
      3) return ;;
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
  echo -e "${YELLOW}7.${NC} Pterodactyl Theme Installer"
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
    7) theme_installer ;;
    8) full_setup; pause ;;
    9) server_info; pause ;;
    10) exit 0 ;;
    *) echo -e "${RED}Invalid option.${NC}"; pause ;;
  esac
done
