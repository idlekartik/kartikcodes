#!/usr/bin/env bash
set -Eeuo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
MAGENTA="\033[0;35m"
WHITE="\033[1;37m"
DIM="\033[2m"
NC="\033[0m"

SITE_URL="https://idlekartik.github.io/kartikcodes"
PANEL_DIR="${PANEL_DIR:-/var/www/pterodactyl}"
PTERO_INSTALLER_URL="https://pterodactyl-installer.se"

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo -e "${RED}Run as root.${NC}"
    echo "bash <(curl -s ${SITE_URL}/scripts/install.sh)"
    exit 1
  fi
}

pause_screen() {
  echo
  read -rp "Press Enter..."
}

type_text() {
  local text="$1"
  local delay="${2:-0.01}"
  local i
  for ((i=0; i<${#text}; i++)); do
    printf "%s" "${text:$i:1}"
    sleep "$delay"
  done
  echo
}

spinner() {
  local pid="$1"
  local msg="$2"
  local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r${RED}%s${NC} $msg" "${frames[$i]}"
    i=$(( (i + 1) % ${#frames[@]} ))
    sleep 0.08
  done
  printf "\r${GREEN}✓${NC} $msg\n"
}

run_with_spinner() {
  local msg="$1"
  shift
  ("$@" >/tmp/kartikextras-last.log 2>&1) &
  local pid=$!
  spinner "$pid" "$msg"
  wait "$pid" || {
    echo -e "${RED}Failed: $msg${NC}"
    echo -e "${YELLOW}Last log:${NC}"
    tail -40 /tmp/kartikextras-last.log || true
    return 1
  }
}

progress_bar() {
  local label="$1"
  echo -ne "${CYAN}$label${NC} "
  for i in {1..30}; do
    echo -ne "${RED}█${NC}"
    sleep 0.025
  done
  echo -e " ${GREEN}done${NC}"
}

intro_animation() {
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
  echo -e "${NC}${WHITE}        K A R T I K E X T R A S${NC}"
  echo -e "${YELLOW}        Made by KartikExtras${NC}"
  echo
  progress_bar "Loading UI"
  progress_bar "Checking modules"
  progress_bar "Preparing menu"
}

banner() {
  clear
  echo -e "${RED}"
  cat <<'BANNER'
╔════════════════════════════════════════════════════════════╗
║              KARTIKEXTRAS INSTALLER PORTAL               ║
╚════════════════════════════════════════════════════════════╝
BANNER
  echo -e "${NC}${YELLOW}Made by KartikExtras${NC}"
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

  run_with_spinner "apt update" apt-get update -y
  run_with_spinner "apt upgrade" apt-get upgrade -y
  run_with_spinner "install useful packages" apt-get install -y curl wget git unzip zip tar htop nano vim ufw ca-certificates gnupg lsb-release software-properties-common net-tools dnsutils jq screen tmux cron logrotate build-essential
  run_with_spinner "cleanup packages" apt-get autoremove -y
  apt-get autoclean -y >/dev/null 2>&1 || true

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
  sysctl --system >/dev/null 2>&1 || true

  cat >/etc/security/limits.d/99-kartikextras.conf <<'EOF'
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

  if ! swapon --show | grep -q "/swapfile"; then
    RAM_MB=$(free -m | awk '/Mem:/ {print $2}')
    if [[ "${RAM_MB:-0}" -lt 4096 ]]; then
      echo -e "${CYAN}Creating 2GB swap...${NC}"
      fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
    fi
  fi

  ufw allow OpenSSH >/dev/null 2>&1 || true
  ufw allow 22/tcp >/dev/null 2>&1 || true
  ufw allow 80/tcp >/dev/null 2>&1 || true
  ufw allow 443/tcp >/dev/null 2>&1 || true
  ufw allow 8080/tcp >/dev/null 2>&1 || true
  ufw allow 2022/tcp >/dev/null 2>&1 || true
  ufw allow 25565/tcp >/dev/null 2>&1 || true
  ufw allow 25565/udp >/dev/null 2>&1 || true
  echo -e "${GREEN}VPS Optimizer complete.${NC}"
}

install_docker() {
  need_root
  echo -e "${CYAN}Installing Docker...${NC}"
  run_with_spinner "apt update" apt-get update -y
  run_with_spinner "install Docker requirements" apt-get install -y curl ca-certificates gnupg lsb-release
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
  apt-get install -y docker-compose-plugin || true
  ufw allow 8080/tcp >/dev/null 2>&1 || true
  ufw allow 2022/tcp >/dev/null 2>&1 || true
  ufw allow 25565/tcp >/dev/null 2>&1 || true
  ufw allow 25565/udp >/dev/null 2>&1 || true
  docker --version || true
  docker compose version || true
  echo -e "${GREEN}Docker installed.${NC}"
}

install_java() {
  need_root
  run_with_spinner "install Java 21" bash -c "apt-get update -y && apt-get install -y openjdk-21-jdk"
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
  ufw allow 25565/tcp >/dev/null 2>&1 || true
  ufw allow 25565/udp >/dev/null 2>&1 || true
  echo -e "${GREEN}Minecraft folder ready: /home/minecraft${NC}"
}

run_pterodactyl_choice() {
  need_root
  local choice="$1"
  local title="$2"

  clear
  echo -e "${RED}$title${NC}"
  echo -e "${YELLOW}Made by KartikExtras${NC}"
  echo "------------------------------------------------------------"
  type_text "Starting installer directly..." 0.015
  progress_bar "Preparing"

  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y curl >/dev/null 2>&1 || true

  echo -e "${CYAN}Auto selecting install option and auto confirming yes...${NC}"
  echo -e "${DIM}Panel = 0, Wings = 1, Panel + Wings = 2${NC}"
  echo -e "${DIM}If installer asks domain/email/password/database details, fill those normally.${NC}"
  sleep 1

  # Auto answers:
  # 1st line: install mode [0/1/2]
  # 2nd line: y for "Are you sure you want to proceed?"
  # Extra y lines are harmless if not used.
  {
    printf "%s\n" "$choice"
    printf "y\n"
    printf "y\n"
  } | bash <(curl -s "$PTERO_INSTALLER_URL")
}

pterodactyl_menu() {
  need_root
  while true; do
    clear
    echo -e "${RED}KartikExtras Pterodactyl Install Menu${NC}"
    echo -e "${YELLOW}Made by KartikExtras${NC}"
    echo "------------------------------------------------------------"
    echo -e "${YELLOW}1.${NC} Panel Install"
    echo -e "${YELLOW}2.${NC} Wings Install"
    echo -e "${YELLOW}3.${NC} Panel + Wings Install"
    echo -e "${YELLOW}4.${NC} Back"
    echo "------------------------------------------------------------"
    read -rp "Choose option: " p
    case "$p" in
      1) run_pterodactyl_choice "0" "KartikExtras Panel Install"; pause_screen ;;
      2) run_pterodactyl_choice "1" "KartikExtras Wings Install"; pause_screen ;;
      3) run_pterodactyl_choice "2" "KartikExtras Panel + Wings Install"; pause_screen ;;
      4) return ;;
      *) echo "Invalid"; pause_screen ;;
    esac
  done
}

blueprint_installer() {
  need_root
  clear
  echo -e "${RED}KartikExtras Blueprint Installer${NC}"
  echo -e "${YELLOW}Made by KartikExtras${NC}"
  echo "------------------------------------------------------------"
  echo "This starts the Blueprint setup needed for .blueprint files."
  echo "External installer may show its own banner while running."
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

  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y curl >/dev/null 2>&1 || true

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
    echo -e "${YELLOW}2.${NC} MC Plugins"
    echo -e "${YELLOW}3.${NC} Minecraft Player Manager"
    echo -e "${YELLOW}4.${NC} Nebula Theme"
    echo -e "${YELLOW}5.${NC} Snowflakes Theme"
    echo -e "${YELLOW}6.${NC} Subdomains"
    echo -e "${YELLOW}7.${NC} Version Changer"
    echo -e "${YELLOW}8.${NC} Euphoria Theme"
    echo -e "${YELLOW}9.${NC} Loader"
    echo -e "${YELLOW}10.${NC} Back"
    echo "------------------------------------------------------------"
    read -rp "Choose option: " t
    case "$t" in
      1) blueprint_installer; pause_screen ;;
      2) install_blueprint_file "mcplugins.blueprint" "MC Plugins"; pause_screen ;;
      3) install_blueprint_file "minecraftplayermanager.blueprint" "Minecraft Player Manager"; pause_screen ;;
      4) install_blueprint_file "nebula.blueprint" "Nebula Theme"; pause_screen ;;
      5) install_blueprint_file "snowflakes.blueprint" "Snowflakes Theme"; pause_screen ;;
      6) install_blueprint_file "subdomains.blueprint" "Subdomains"; pause_screen ;;
      7) install_blueprint_file "versionchanger.blueprint" "Version Changer"; pause_screen ;;
      8) install_blueprint_file "euphoriatheme.blueprint" "Euphoria Theme"; pause_screen ;;
      9) install_blueprint_file "loader.blueprint" "Loader"; pause_screen ;;
      10) return ;;
      *) echo "Invalid"; pause_screen ;;
    esac
  done
}

full_setup() {
  vps_optimizer
  install_docker
  pterodactyl_menu
}

intro_animation

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
    1) vps_optimizer; pause_screen ;;
    2) install_docker; pause_screen ;;
    3) install_java; pause_screen ;;
    4) install_node; pause_screen ;;
    5) minecraft_server_setup; pause_screen ;;
    6) pterodactyl_menu ;;
    7) theme_installer ;;
    8) full_setup; pause_screen ;;
    9) server_info; pause_screen ;;
    10) exit 0 ;;
    *) echo -e "${RED}Invalid option.${NC}"; pause_screen ;;
  esac
done
