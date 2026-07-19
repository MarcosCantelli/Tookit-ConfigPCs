#!/usr/bin/env bash
# system.sh - atualização de pacotes do sistema (repositório oficial da distro).

update_system_packages() {
    log "Gerenciador de pacotes detectado: $PKG_MANAGER"
    case "$PKG_MANAGER" in
        apt)
            apt-get update && apt-get upgrade -y
            ;;
        dnf)
            dnf upgrade -y
            ;;
        *)
            log "Gerenciador de pacotes não reconhecido (nem apt nem dnf). Nenhuma atualização executada." "WARN"
            return
            ;;
    esac
    log "Pacotes do sistema atualizados." "OK"
}

invoke_system_update() {
    update_system_packages
}
