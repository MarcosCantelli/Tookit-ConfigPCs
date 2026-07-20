#!/usr/bin/env bash
# common.sh - logging, checagem de root, detecção de distro/gerenciador de pacotes.
# Árvore separada de linux/ (aquela é servidor; esta é estação de trabalho de dev).

LOG_FILE=""

init_logging() {
    local root_path="$1"
    mkdir -p "$root_path/logs"
    LOG_FILE="$root_path/logs/setup_$(date +%Y%m%d_%H%M%S).log"
    log "===== Sessão iniciada ====="
}

log() {
    local message="$1"
    local level="${2:-INFO}"
    local color="\033[0m"
    case "$level" in
        WARN) color="\033[33m" ;;
        ERROR) color="\033[31m" ;;
        OK) color="\033[32m" ;;
    esac

    local line="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
    echo -e "${color}${line}\033[0m"
    if [ -n "$LOG_FILE" ]; then
        echo "$line" >> "$LOG_FILE"
    fi
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "Este script precisa rodar como root. Rode com: sudo $0" "ERROR"
        exit 1
    fi
}

detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    else
        echo "unknown"
    fi
}

PKG_MANAGER="$(detect_package_manager)"

# Usuário "de verdade" (não-root) que chamou o sudo - útil pra instalar coisas de
# usuário (Flatpak, PATH do shell dele, etc.) em vez de jogar tudo em /root.
TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER")}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

# Roda um comando como o TARGET_USER com a sessão D-Bus dele - necessário pro
# flatpak/Bottles funcionarem direito quando o script inteiro roda via sudo/root.
run_as_target_user() {
    local uid
    uid="$(id -u "$TARGET_USER")"
    sudo -u "$TARGET_USER" \
        XDG_RUNTIME_DIR="/run/user/$uid" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
        bash -c "$1"
}
