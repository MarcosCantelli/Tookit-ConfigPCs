#!/usr/bin/env bash
# drivers.sh - "atualizar drivers" no Linux é, na prática, atualizar os pacotes do sistema
# (o kernel e a distro já distribuem os drivers via repositório oficial - não existe um
# instalador de terceiros por fabricante como no Windows). Em Ubuntu/derivados, também
# rodamos o utilitário oficial da Canonical para detectar o melhor driver de GPU disponível.

update_system_packages() {
    log "Gerenciador de pacotes detectado: $PKG_MANAGER"
    case "$PKG_MANAGER" in
        apt)
            apt-get update && apt-get upgrade -y
            ;;
        dnf)
            dnf upgrade -y
            ;;
        pacman)
            pacman -Syu --noconfirm
            ;;
        *)
            log "Gerenciador de pacotes não reconhecido (nem apt, dnf ou pacman). Nenhuma atualização executada." "WARN"
            return
            ;;
    esac
    log "Pacotes do sistema atualizados." "OK"
}

install_extra_drivers() {
    if command -v ubuntu-drivers >/dev/null 2>&1; then
        log "Detectando/instalando o driver de GPU recomendado (ubuntu-drivers, oficial da Canonical)..."
        ubuntu-drivers autoinstall
        log "ubuntu-drivers finalizado. Reinicie a máquina quando possível." "OK"
    else
        log "ubuntu-drivers não disponível nesta distro; pulei a etapa de driver de GPU dedicado." "WARN"
    fi
}

invoke_driver_update() {
    update_system_packages
    install_extra_drivers
}
