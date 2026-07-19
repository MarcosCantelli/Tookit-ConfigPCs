#!/usr/bin/env bash
# software.sh - instalação de programas básicos usando SOMENTE repositórios oficiais:
# repositório da própria distro, repositório oficial da Google (Chrome) e, no Fedora,
# RPM Fusion (repositório recomendado pelo próprio projeto Fedora para pacotes como VLC
# que não podem ir no repositório principal por causa de patente/licença de codec).

ensure_rpmfusion() {
    if [ "$PKG_MANAGER" != "dnf" ]; then return; fi

    if ! dnf repolist 2>/dev/null | grep -qi rpmfusion-free; then
        log "Habilitando RPM Fusion (free) - repositório recomendado pelo projeto Fedora para VLC/codecs..." "WARN"
        dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    fi
    if ! dnf repolist 2>/dev/null | grep -qi rpmfusion-nonfree; then
        dnf install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    fi
}

install_google_chrome() {
    log "Instalando Google Chrome..."
    case "$PKG_MANAGER" in
        apt)
            local deb="/tmp/google-chrome-stable_current_amd64.deb"
            wget -q -O "$deb" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
            apt-get install -y "$deb"
            rm -f "$deb"
            ;;
        dnf)
            cat > /etc/yum.repos.d/google-chrome.repo <<'REPO'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
REPO
            dnf install -y google-chrome-stable
            ;;
        pacman)
            log "Chrome não está nos repositórios oficiais do Arch (só via AUR, que não é oficial). Pulando." "WARN"
            return
            ;;
        *)
            log "Gerenciador de pacotes não reconhecido; pulando Chrome." "WARN"
            return
            ;;
    esac
    log "Google Chrome instalado." "OK"
}

install_vlc() {
    log "Instalando VLC..."
    case "$PKG_MANAGER" in
        apt) apt-get install -y vlc ;;
        dnf)
            ensure_rpmfusion
            dnf install -y vlc
            ;;
        pacman) pacman -S --noconfirm vlc ;;
        *) log "Gerenciador de pacotes não reconhecido; pulando VLC." "WARN"; return ;;
    esac
    log "VLC instalado." "OK"
}

install_generic_package() {
    # $1 = nome amigável, $2 = pacote(s) apt, $3 = pacote(s) dnf, $4 = pacote(s) pacman
    local name="$1" apt_pkg="$2" dnf_pkg="$3" pacman_pkg="$4"
    local pkg=""

    case "$PKG_MANAGER" in
        apt) pkg="$apt_pkg" ;;
        dnf) pkg="$dnf_pkg" ;;
        pacman) pkg="$pacman_pkg" ;;
    esac

    if [ -z "$pkg" ] || [ "$pkg" = "--" ]; then
        log "Sem pacote configurado para '$name' em $PKG_MANAGER. Pulando." "WARN"
        return
    fi

    if [ "$PKG_MANAGER" = "dnf" ]; then
        ensure_rpmfusion
    fi

    log "Instalando $name ($pkg)..."
    case "$PKG_MANAGER" in
        apt) apt-get install -y $pkg ;;
        dnf) dnf install -y $pkg ;;
        pacman) pacman -S --noconfirm $pkg ;;
        *) log "Gerenciador de pacotes não reconhecido; pulando $name." "WARN"; return ;;
    esac
    log "$name instalado." "OK"
}

invoke_software_install() {
    if [ "$INSTALL_CHROME" = "true" ]; then
        install_google_chrome
    fi

    install_vlc

    for entry in "${SOFTWARE_LIST[@]}"; do
        IFS='|' read -r name apt_pkg dnf_pkg pacman_pkg <<< "$entry"
        install_generic_package "$name" "$apt_pkg" "$dnf_pkg" "$pacman_pkg"
    done

    log "Instalação de programas básicos concluída." "OK"
}
