#!/usr/bin/env bash
# setup.sh - entrypoint do toolkit de pós-formatação para servidores Linux
# (Ubuntu Server / Oracle Linux). Rode com sudo.
#
#   sudo ./setup.sh

set -u

ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=modules/common.sh
source "$ROOT_PATH/modules/common.sh"
# shellcheck source=config/config.sh
source "$ROOT_PATH/config/config.sh"
# shellcheck source=modules/system.sh
source "$ROOT_PATH/modules/system.sh"
# shellcheck source=modules/software.sh
source "$ROOT_PATH/modules/software.sh"
# shellcheck source=modules/network.sh
source "$ROOT_PATH/modules/network.sh"

require_root
init_logging "$ROOT_PATH"
log "Gerenciador de pacotes: $PKG_MANAGER"

show_menu() {
    echo ""
    echo "========================================================="
    echo " Toolkit de pós-formatação (Linux - servidor)"
    echo "========================================================="
    echo " 1) Atualizar sistema (pacotes oficiais da distro)"
    echo " 2) Instalar Docker (Engine + Compose)"
    echo " 3) Instalar ferramentas básicas (net-tools, open-vm-tools, htop, tmux...)"
    echo " 4) Configurar IP fixo"
    echo " 0) Executar tudo (1 -> 2 -> 3) [não inclui IP fixo - é passo separado de propósito]"
    echo " Q) Sair"
    echo "========================================================="
}

invoke_all() {
    invoke_system_update
    invoke_docker_install
    invoke_basic_tools_install
}

while true; do
    show_menu
    read -rp "Escolha uma opção: " choice
    case "$choice" in
        1) invoke_system_update ;;
        2) invoke_docker_install ;;
        3) invoke_basic_tools_install ;;
        4) invoke_static_ip_config ;;
        0) invoke_all ;;
        q|Q) log "Encerrando."; break ;;
        *) echo "Opção inválida." ;;
    esac
done
