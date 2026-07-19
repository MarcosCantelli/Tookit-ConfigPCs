#!/usr/bin/env bash
# software.sh - Docker (repositório oficial docker.com) e ferramentas básicas de servidor
# (repositório oficial da própria distro). Sem nada gráfico - o foco aqui é servidor
# (Ubuntu Server / Oracle Linux), não estação de trabalho.

install_docker() {
    if command -v docker >/dev/null 2>&1; then
        log "Docker já está instalado."
        return
    fi

    log "Instalando Docker (repositório oficial docker.com)..."
    case "$PKG_MANAGER" in
        apt)
            apt-get update
            apt-get install -y ca-certificates curl gnupg
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            chmod a+r /etc/apt/keyrings/docker.asc
            local codename
            codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $codename stable" \
                > /etc/apt/sources.list.d/docker.list
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        dnf)
            # Oracle Linux não tem repo próprio do Docker CE - o próprio Docker recomenda
            # usar o repo do CentOS, que é compatível (RHEL-based).
            dnf -y install dnf-plugins-core
            dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            log "Gerenciador de pacotes não suportado para instalação do Docker (só apt/dnf)." "ERROR"
            return
            ;;
    esac

    systemctl enable --now docker
    log "Docker instalado e habilitado (docker --version / docker compose version)." "OK"
    log "Se quiser rodar docker sem sudo, adicione seu usuário ao grupo 'docker' manualmente (usermod -aG docker <usuario>) - isso equivale a acesso root, então não faço isso automaticamente." "WARN"
}

install_generic_package() {
    # $1 = nome amigável, $2 = pacote(s) apt, $3 = pacote(s) dnf
    local name="$1" apt_pkg="$2" dnf_pkg="$3"
    local pkg=""

    case "$PKG_MANAGER" in
        apt) pkg="$apt_pkg" ;;
        dnf) pkg="$dnf_pkg" ;;
    esac

    if [ -z "$pkg" ] || [ "$pkg" = "--" ]; then
        log "Sem pacote configurado para '$name' em $PKG_MANAGER. Pulando." "WARN"
        return
    fi

    log "Instalando $name ($pkg)..."
    case "$PKG_MANAGER" in
        apt) apt-get install -y $pkg ;;
        dnf) dnf install -y $pkg ;;
        *) log "Gerenciador de pacotes não reconhecido; pulando $name." "WARN"; return ;;
    esac
    log "$name instalado." "OK"
}

invoke_basic_tools_install() {
    for entry in "${SOFTWARE_LIST[@]}"; do
        IFS='|' read -r name apt_pkg dnf_pkg <<< "$entry"
        install_generic_package "$name" "$apt_pkg" "$dnf_pkg"
    done

    if systemctl list-unit-files 2>/dev/null | grep -q '^vmtoolsd\.service'; then
        log "Habilitando serviço open-vm-tools (vmtoolsd)..."
        systemctl enable --now vmtoolsd
    fi

    log "Instalação de ferramentas básicas concluída." "OK"
}

invoke_docker_install() {
    if [ "$INSTALL_DOCKER" = "true" ]; then
        install_docker
    fi
}
