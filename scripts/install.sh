#!/usr/bin/env bash
set -Eeuo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

SITE_URL="https://idlekartik.github.io/kartikcodes"
PANEL_DIR="${PANEL_DIR:-/var/www/pterodactyl}"

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo -e "${RED}Run as root.${NC}"
    echo "bash <(curl -s ${SITE_URL}/scripts/install.sh)"
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
  apt-get update -y
  apt-get upgrade -y
  apt-get install -y curl wget git unzip zip tar htop nano vim ufw ca-certificates gnupg lsb-release software-properties-common net-tools dnsutils jq screen tmux cron logrotate build-essential
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
net.ipv4.tcp_max_syn_backlog=65535
net.core.netdev_max_backlog=16384
EOF
  sysctl --system || true

  cat >/etc/security/limits.d/99-kartikextras.conf <<'EOF'
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

  if ! swapon --show | grep -q "/swapfile"; then
    RAM_MB=$(free -m | awk '/Mem:/ {print $2}')
    if [[ "${RAM_MB:-0}" -lt 4096 ]]; then
      fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
    fi
  fi

  ufw allow OpenSSH || true
  ufw allow 22/tcp || true
  ufw allow 80/tcp || true
  ufw allow 443/tcp || true
  ufw allow 8080/tcp || true
  ufw allow 2022/tcp || true
  ufw allow 25565/tcp || true
  ufw allow 25565/udp || true
  echo -e "${GREEN}VPS Optimizer complete.${NC}"
}

install_docker() {
  need_root
  echo -e "${CYAN}Installing Docker...${NC}"
  apt-get update -y
  apt-get install -y curl ca-certificates gnupg lsb-release
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
  apt-get install -y docker-compose-plugin || true
  ufw allow 8080/tcp || true
  ufw allow 2022/tcp || true
  ufw allow 25565/tcp || true
  ufw allow 25565/udp || true
  docker --version || true
  docker compose version || true
  echo -e "${GREEN}Docker installed.${NC}"
}

install_java() {
  need_root
  apt-get update -y
  apt-get install -y openjdk-21-jdk
  java -version
}

install_node() {
  need_root
  apt-get update -y
  apt-get install -y curl
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
  node -v
  npm -v
}

minecraft_server_setup() {
  need_root
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
      2) install_docker; pause ;;
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
        read -rp "Type YES to run Panel/Wings auto-installer: " confirm
        [[ "$confirm" == "YES" ]] && bash <(curl -s https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer/master/install.sh) || echo "Cancelled."
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
  echo "------------------------------------------------------------"
  read -rp "Type YES to run Blueprint installer: " confirm
  if [[ "$confirm" == "YES" ]]; then
    bash <(curl -fsSL https://github.com/infinityForge-labs/blueprint-installer/raw/refs/heads/main/ultra-install.sh)
  else
    echo "Cancelled."
  fi
}

install_blueprint_file() {
  need_root
  local file="$1"
  local label="$2"

  clear
  echo -e "${RED}KartikExtras Theme Install${NC}"
  echo -e "${YELLOW}Made by KartikExtras${NC}"
  echo "------------------------------------------------------------"
  echo "Selected: $label"
  echo "File: $file"
  echo "URL: $SITE_URL/themes/$file"
  echo "------------------------------------------------------------"
  read -rp "Type YES to install this blueprint: " confirm
  if [[ "$confirm" != "YES" ]]; then
    echo "Cancelled."
    return
  fi

  apt-get update -y
  apt-get install -y curl

  local tmp="/tmp/kartikextras-blueprint-$$"
  mkdir -p "$tmp"
  local localfile="$tmp/$file"

  echo -e "${CYAN}Downloading $label...${NC}"
  if ! curl -fsSL "$SITE_URL/themes/$file" -o "$localfile"; then
    echo -e "${RED}Download failed. Check GitHub upload path: themes/$file${NC}"
    return
  fi

  echo -e "${CYAN}Installing with Blueprint...${NC}"

  if command -v blueprint >/dev/null 2>&1; then
    blueprint -install "$localfile" || blueprint install "$localfile" || blueprint -i "$localfile"
  elif [[ -f "$PANEL_DIR/blueprint.sh" ]]; then
    cd "$PANEL_DIR"
    bash blueprint.sh -install "$localfile" || bash blueprint.sh install "$localfile" || bash blueprint.sh -i "$localfile"
  elif [[ -f "/usr/local/bin/blueprint" ]]; then
    /usr/local/bin/blueprint -install "$localfile" || /usr/local/bin/blueprint install "$localfile" || /usr/local/bin/blueprint -i "$localfile"
  else
    echo -e "${RED}Blueprint command not found.${NC}"
    echo -e "${YELLOW}Install Blueprint first: Theme Installer -> option 1${NC}"
    echo "Downloaded file is here: $localfile"
    return
  fi

  if [[ -d "$PANEL_DIR" && -f "$PANEL_DIR/artisan" ]]; then
    cd "$PANEL_DIR"
    php artisan view:clear || true
    php artisan cache:clear || true
    php artisan config:clear || true
    php artisan route:clear || true
  fi

  echo -e "${GREEN}Installed: $label${NC}"
}

theme_installer() {
  need_root
  while true; do
    clear
    echo -e "${RED}KartikExtras Pterodactyl Theme Installer${NC}"
    echo -e "${YELLOW}Made by KartikExtras${NC}"
    echo "------------------------------------------------------------"
    echo -e "${YELLOW}1.${NC} Blueprint Installer for Pterodactyl"
    echo -e "${YELLOW}1.${NC} MC Plugins"
    echo -e "${YELLOW}2.${NC} Minecraft Player Manager"
    echo -e "${YELLOW}3.${NC} Nebula Theme"
    echo -e "${YELLOW}4.${NC} Snowflakes Theme"
    echo -e "${YELLOW}5.${NC} Subdomains"
    echo -e "${YELLOW}6.${NC} Version Changer"
    echo -e "${YELLOW}7.${NC} Euphoria Theme"
    echo -e "${YELLOW}8.${NC} Loader"
    echo -e "${YELLOW}9.${NC} Back"
    echo "------------------------------------------------------------"
    read -rp "Choose option: " t
    case "$t" in
      1) blueprint_installer; pause ;;
      1) install_blueprint_file "mcplugins.blueprint" "MC Plugins"; pause ;;
      2) install_blueprint_file "minecraftplayermanager.blueprint" "Minecraft Player Manager"; pause ;;
      3) install_blueprint_file "nebula.blueprint" "Nebula Theme"; pause ;;
      4) install_blueprint_file "snowflakes.blueprint" "Snowflakes Theme"; pause ;;
      5) install_blueprint_file "subdomains.blueprint" "Subdomains"; pause ;;
      6) install_blueprint_file "versionchanger.blueprint" "Version Changer"; pause ;;
      7) install_blueprint_file "euphoriatheme.blueprint" "Euphoria Theme"; pause ;;
      8) install_blueprint_file "loader.blueprint" "Loader"; pause ;;
      9) return ;;
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
