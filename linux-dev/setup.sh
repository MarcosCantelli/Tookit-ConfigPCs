#!/usr/bin/env bash
# setup.sh - Dev Kit para estação de trabalho Linux (Ubuntu Desktop / Fedora Workstation).
# Separado do toolkit de servidor (../linux/) de propósito - são contextos diferentes.
#
#   sudo ./setup.sh

set -u

ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=modules/common.sh
source "$ROOT_PATH/modules/common.sh"
# shellcheck source=config/config.sh
source "$ROOT_PATH/config/config.sh"
# shellcheck source=modules/devkit.sh
source "$ROOT_PATH/modules/devkit.sh"
# shellcheck source=modules/terminal.sh
source "$ROOT_PATH/modules/terminal.sh"

require_root
init_logging "$ROOT_PATH"
log "Gerenciador de pacotes: $PKG_MANAGER | Usuário alvo: $TARGET_USER"

show_menu() {
    echo ""
    echo "========================================================="
    echo " Dev Kit (Linux desktop)"
    echo "========================================================="
    echo " 1) Git"
    echo " 2) VSCode"
    echo " 3) Java JDK 21.0.11 (Oracle) + JAVA_HOME"
    echo " 4) Maven + MAVEN_HOME"
    echo " 5) Node.js LTS (NodeSource)"
    echo " 6) Python (atualiza o que já vem instalado + pip/venv)"
    echo " 7) Terminal tipo MobaXterm (Bottles+MobaXterm ou Tabby)"
    echo " 0) Tudo (1 -> 6, sem o passo 7 - esse é interativo de propósito)"
    echo " Q) Sair"
    echo "========================================================="
}

while true; do
    show_menu
    read -rp "Escolha uma opção: " choice
    case "$choice" in
        1) install_dev_git ;;
        2) install_dev_vscode ;;
        3) install_dev_java_jdk ;;
        4) install_dev_maven ;;
        5) install_dev_nodejs ;;
        6) install_dev_python ;;
        7) invoke_terminal_client_install ;;
        0) invoke_devkit_base_install ;;
        q|Q) log "Encerrando."; break ;;
        *) echo "Opção inválida." ;;
    esac
done
