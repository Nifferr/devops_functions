#!/usr/bin/env bash
# ==============================================================================
# SystemVault - Unified Linux Optimization & Setup
# Managed by Antigravity (AI Coding Assistant)
# ==============================================================================
set -Eeuo pipefail

# ------------------------------------------------------------------------------
# Colors & Typography
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Icons
INFO="[${BLUE}i${RESET}]"
SUCCESS="[${GREEN}✓${RESET}]"
WARNING="[${YELLOW}!${RESET}]"
ERROR="[${RED}✗${RESET}]"
EXEC="[${CYAN}*${RESET}]"

# ------------------------------------------------------------------------------
# Global Settings
# ------------------------------------------------------------------------------
SCRIPT_NAME="$(basename "$0")"
BACKUP_DIR="/var/backups/system-vault"
LOG_DIR="/var/log/system-vault"
TIMESTAMP="$(date +%F-%H%M%S)"

# ------------------------------------------------------------------------------
# Root & User Check
# ------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  echo -e "${ERROR} ${BOLD}Este script deve ser executado como root.${RESET}"
  echo -e "Use: ${CYAN}sudo ./${SCRIPT_NAME}${RESET}"
  exit 1
fi

TARGET_USER="${SUDO_USER:-${PKEXEC_UID:-}}"
if [[ -z "${TARGET_USER:-}" || "$TARGET_USER" == "root" ]]; then
  TARGET_USER="$(logname 2>/dev/null || true)"
fi
if [[ -z "${TARGET_USER:-}" || "$TARGET_USER" == "root" ]]; then
  TARGET_USER="$(awk -F: '$3>=1000 && $3<65534 {print $1; exit}' /etc/passwd)"
fi
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_UID="$(id -u "$TARGET_USER")"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# ------------------------------------------------------------------------------
# UI Helpers
# ------------------------------------------------------------------------------
print_banner() {
  clear
  echo -e "${CYAN}${BOLD}"
  cat <<'EOF'
   _____                      __      __         _ _ 
  / ____|                     \ \    / /        | | |
 | (___  _   _ ___| |_ ___ _ __\ \  / /_ _ _   _| | |_
  \___ \| | | / __| __/ _ \ '_ \ \/ / _` | | | | | __|
  ____) | |_| \__ \ ||  __/ | | \  / (_| | |_| | | |_ 
 |_____/ \__, |___/\__\___|_| |_|\/ \__,_|\__,_|_|\__|
          __/ |                                      
         |___/                                       
EOF
  echo -e "${RESET}${BOLD}Unified Linux Maintenance & Dev Environment${RESET}"
  echo -e "--------------------------------------------------------"
  echo -e "Usuario: ${YELLOW}${TARGET_USER}${RESET} | Sistema: ${YELLOW}$(uname -n)${RESET}"
  echo -e "--------------------------------------------------------\n"
}

log_info() { echo -e "${INFO} $*"; }
log_success() { echo -e "${SUCCESS} $*"; }
log_warn() { echo -e "${WARNING} $*"; }
log_err() { echo -e "${ERROR} $*"; }

run_as_user() {
  sudo -u "$TARGET_USER" env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${TARGET_UID}/bus" XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" "$@"
}

ask_yes_no() {
  local prompt="$1" default="${2:-S}" reply
  while true; do
    read -r -p "$(echo -e "${BOLD}${prompt}${RESET} [${default}/$([[ "$default" == "S" ]] && echo N || echo S)]: ")" reply || true
    reply="${reply:-$default}"
    case "${reply^^}" in
      S|Y) return 0 ;;
      N) return 1 ;;
    esac
  done
}

# 1. TWEAKS & IMPROVEMENTS
# ------------------------
apply_tweaks() {
  print_banner
  log_info "Iniciando otimização do sistema..."

  # Kernel Tuning
  if ask_yes_no "Deseja aplicar tuning de kernel (swappiness, inotify, network)?"; then
    SYSCTL_CONF="/etc/sysctl.d/99-vault-optimized.conf"
    cat <<EOF > "$SYSCTL_CONF"
# SystemVault Optimizations
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
fs.file-max = 2097152
net.core.somaxconn = 1024
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
fs.inotify.max_user_watches = 524288
EOF
    sysctl --system >/dev/null
    log_success "Kernel tuning aplicado com sucesso."
  fi

  # SSD Optimizations
  if ask_yes_no "Deseja habilitar TRIM e otimização de I/O para SSD?"; then
    systemctl enable --now fstrim.timer >/dev/null 2>&1 || log_warn "Não foi possível habilitar fstrim."
    for disk in /sys/block/sd*/queue/scheduler; do
      echo noop > "$disk" 2>/dev/null || true
    done
    log_success "SSD optimizations aplicadas."
  fi

  # GNOME Tweaks
  if command -v gsettings &>/dev/null; then
    if ask_yes_no "Deseja desativar animações do GNOME para maior rapidez?"; then
      run_as_user gsettings set org.gnome.desktop.interface enable-animations false || log_warn "Falha ao alterar animações."
      log_success "Animações desativadas."
    fi
  fi

  # ZRAM Setup
  if ask_yes_no "Deseja instalar ZRAM (Swap compactado em RAM)?"; then
    if apt-cache show zram-tools >/dev/null 2>&1; then
      apt install -y zram-tools
      cat > /etc/default/zramswap <<'ZEOF'
ALGO=zstd
PERCENT=25
PRIORITY=100
ZEOF
      systemctl enable --now zramswap.service || log_warn "Falha ao iniciar ZRAM."
      log_success "ZRAM configurado."
    fi
  fi

  # Snap/Flatpak Clean
  if ask_yes_no "Deseja limpar caches e versões antigas de Snap/Flatpak?"; then
    log_info "Limpando Snaps..."
    set +e
    snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
        snap remove "$snapname" --revision="$revision"
    done
    set -e
    if command -v flatpak &>/dev/null; then
      log_info "Limpando Flatpaks..."
      flatpak uninstall --unused -y
    fi
    log_success "Snaps/Flatpaks limpos."
  fi

  log_info "Limpeza de cache de pacotes..."
  apt autoremove -y && apt autoclean -y
  read -r -p "Pressione Enter para voltar ao menu..."
}

# 2. TOOL INSTALLATION
# --------------------
install_tools() {
  print_banner
  log_info "Instalação de Ferramentas..."

  # Essentials
  if ask_yes_no "Deseja instalar ferramentas essenciais (curl, git, htop, preload)?"; then
    apt update && apt install -y curl git htop preload wget build-essential
    systemctl enable --now preload
    log_success "Tools essenciais instaladas."
  fi

  # ZSH
  if ask_yes_no "Deseja instalar ZSH + Oh My Zsh?"; then
    apt install -y zsh
    # Oh My Zsh install command (non-interactive)
    CHSH=yes RUNZSH=no run_as_user sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
    log_success "ZSH instalado. Reinicie a sessão para aplicar."
  fi

  # Docker
  if ask_yes_no "Deseja instalar Docker & Docker Compose?"; then
    apt install -y ca-certificates gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    usermod -aG docker "$TARGET_USER"
    log_success "Docker instalado. Usuario $TARGET_USER adicionado ao grupo docker."
  fi

  read -r -p "Pressione Enter para voltar ao menu..."
}

# 3. DEBUG & FIXES
# ----------------
debug_fixes() {
  print_banner
  log_info "Debug e Correções..."

  if ask_yes_no "Deseja gerar um relatório de diagnóstico completo?"; then
    REPORT="$LOG_DIR/diag-${TIMESTAMP}.log"
    {
      echo "=== OS Version ==="
      cat /etc/os-release
      echo -e "\n=== CPU/RAM ==="
      free -h
      echo -e "\n=== Failed Services ==="
      systemctl --failed --no-pager
      echo -e "\n=== Journal Errors ==="
      journalctl -p 3 -xb --no-pager | tail -n 20
    } > "$REPORT"
    log_success "Relatorio salvo em: $REPORT"
  fi

  if ask_yes_no "Deseja resetar extensões do GNOME e limpar cache gráfico?"; then
    run_as_user gsettings set org.gnome.shell disable-user-extensions true || true
    rm -rf "$TARGET_HOME/.cache/gnome-shell" "$TARGET_HOME/.cache/mesa_shader_cache" 2>/dev/null || true
    log_success "Cache limpo e extensões desativadas."
  fi

  if ask_yes_no "Deseja limpar logs do journal (preservar 7 dias)?"; then
    journalctl --vacuum-time=7d
    log_success "Logs limpos."
  fi

  read -r -p "Pressione Enter para voltar ao menu..."
}

# 4. DEVOPS SETUP
# ---------------
devops_setup() {
  print_banner
  log_info "DevOps Setup (K8s & Cloud Native)..."

  # Kubectl
  if ask_yes_no "Instalar Kubectl?"; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
    log_success "Kubectl instalado."
  fi

  # Helm
  if ask_yes_no "Instalar Helm?"; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    log_success "Helm instalado."
  fi

  # K3s (Lightweight K8s)
  if ask_yes_no "Deseja instalar K3s (cluster local leve)?"; then
    curl -sfL https://get.k3s.io | sh -
    log_success "K3s instalado. Use 'sudo k3s kubectl get nodes' para testar."
  fi

  # GitLens/K9s etc (suggested tools)
  if ask_yes_no "Instalar ferramentas de monitoramento (K9s, BTM)?"; then
    log_info "Instalando K9s..."
    curl -sS https://webinstall.dev/k9s | bash || true
    apt install -y bottom || true
    log_success "Ferramentas instaladas."
  fi

  read -r -p "Pressione Enter para voltar ao menu..."
}

# ------------------------------------------------------------------------------
# Main Menu
# ------------------------------------------------------------------------------
while true; do
  print_banner
  echo -e "${BOLD}Menu Principal:${RESET}"
  echo -e "${CYAN}1)${RESET} Tweaks & Melhorias (Kernel, SSD, GNOME)"
  echo -e "${CYAN}2)${RESET} Instalação de Ferramentas (ZSH, Docker, CLI)"
  echo -e "${CYAN}3)${RESET} Debug & Correção de Erros"
  echo -e "${CYAN}4)${RESET} DevOps Setup (Kubectl, Helm, K3s)"
  echo -e "${CYAN}5)${RESET} One-Click Optimization (Recomendado)"
  echo -e "${CYAN}0)${RESET} Sair"
  echo
  read -r -p "Escolha uma opcao: " opt

  case "$opt" in
    1) apply_tweaks ;;
    2) install_tools ;;
    3) debug_fixes ;;
    4) devops_setup ;;
    5) 
      log_info "Iniciando otimização ONE-CLICK recomendada..."
      
      # 1. Kernel Optimization
      SYSCTL_CONF="/etc/sysctl.d/99-vault-optimized.conf"
      cat <<EOF > "$SYSCTL_CONF"
vm.swappiness = 10
vm.vfs_cache_pressure = 50
fs.inotify.max_user_watches = 524288
EOF
      sysctl --system >/dev/null
      
      # 2. SSD Trim
      systemctl enable --now fstrim.timer >/dev/null 2>&1 || true
      
      # 3. Clean Apt
      apt update && apt autoremove -y && apt autoclean -y
      
      # 4. Journal Vacuum
      journalctl --vacuum-time=7d
      
      log_success "Otimização ONE-CLICK concluída com sucesso!"
      sleep 2
      ;;
    0) 
      log_info "Saindo... Tenha um bom dia!"
      exit 0
      ;;
    *) log_err "Opção inválida." ; sleep 1 ;;
  esac
done
