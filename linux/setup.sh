#!/usr/bin/env bash
# setup.sh - entrypoint do toolkit de pós-formatação (Linux). Rode com sudo.
#
#   sudo ./setup.sh

set -u

ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=modules/common.sh
source "$ROOT_PATH/modules/common.sh"
# shellcheck source=config/config.sh
source "$ROOT_PATH/config/config.sh"
# shellcheck source=modules/drivers.sh
source "$ROOT_PATH/modules/drivers.sh"
# shellcheck source=modules/software.sh
source "$ROOT_PATH/modules/software.sh"

require_root
init_logging "$ROOT_PATH"
log "Gerenciador de pacotes: $PKG_MANAGER"

show_menu() {
    echo ""
    echo "========================================================="
    echo " Toolkit de pós-formatação (Linux)"
    echo "========================================================="
    echo " 1) Atualizar sistema/drivers (pacotes oficiais da distro)"
    echo " 2) Instalar programas básicos (Chrome, VLC, unrar, p7zip)"
    echo " 0) Executar tudo"
    echo " Q) Sair"
    echo "========================================================="
}

invoke_all() {
    invoke_driver_update
    invoke_software_install
}

while true; do
    show_menu
    read -rp "Escolha uma opção: " choice
    case "$choice" in
        1) invoke_driver_update ;;
        2) invoke_software_install ;;
        0) invoke_all ;;
        q|Q) log "Encerrando."; break ;;
        *) echo "Opção inválida." ;;
    esac
done
