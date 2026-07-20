#!/usr/bin/env bash
# terminal.sh - MobaXterm não existe nativo pra Linux. Duas opções:
#   1) Bottles (Wine) rodando o MobaXterm.exe do Windows - funciona bem segundo o uso real,
#      mas a automação 100% via CLI do Bottles é recente e pode variar entre versões; o
#      script tenta e avisa se sobrar algum clique manual pra terminar.
#   2) Tabby (ex-Terminus) - cliente de terminal/SSH nativo multiplataforma, mais simples.

ensure_flatpak() {
    if command -v flatpak >/dev/null 2>&1; then return 0; fi

    log "Instalando flatpak (necessário pro Bottles)..."
    case "$PKG_MANAGER" in
        apt) apt-get install -y flatpak ;;
        dnf) dnf install -y flatpak ;;
        *) log "Gerenciador de pacotes não reconhecido; não consigo instalar flatpak." "ERROR"; return 1 ;;
    esac

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

install_moba_via_bottles() {
    ensure_flatpak || return

    if ! command -v unzip >/dev/null 2>&1; then
        case "$PKG_MANAGER" in
            apt) apt-get install -y unzip ;;
            dnf) dnf install -y unzip ;;
        esac
    fi

    log "Instalando Bottles (Flathub)..."
    flatpak install -y flathub com.usebottles.bottles

    log "Baixando o instalador do MobaXterm..."
    local workdir="/tmp/mobaxterm-bottles"
    mkdir -p "$workdir"
    curl -fsSL "$MOBAXTERM_INSTALLER_ZIP_URL" -o "$workdir/moba.zip"
    unzip -o "$workdir/moba.zip" -d "$workdir" >/dev/null
    local msi
    msi="$(find "$workdir" -iname '*.msi' | head -n1)"
    if [ -z "$msi" ]; then
        log "Não encontrei o .msi dentro do zip do MobaXterm." "ERROR"
        return
    fi
    chown -R "$TARGET_USER" "$workdir"

    log "Criando bottle 'MobaXterm' e rodando o instalador (como usuário $TARGET_USER)..."
    if run_as_target_user "flatpak run --command=bottles-cli com.usebottles.bottles new --bottle-name 'MobaXterm' --environment 'application'"; then
        run_as_target_user "flatpak run --command=bottles-cli com.usebottles.bottles run -b 'MobaXterm' -e '$msi'"
        log "Instalador do MobaXterm rodado dentro do bottle. Abra o Bottles (GUI) do usuário $TARGET_USER pra conferir se falta algum clique (ex: aceitar EULA) e criar o atalho." "OK"
    else
        log "Não consegui automatizar 100% via CLI do Bottles (a API muda entre versões e não deu pra testar num ambiente real). Abra o Bottles, crie um bottle manualmente e instale: $msi" "WARN"
    fi
}

install_tabby() {
    log "Instalando Tabby (ex-Terminus)..."
    local api_url="https://api.github.com/repos/${TABBY_GITHUB_REPO}/releases/latest"

    case "$PKG_MANAGER" in
        apt)
            local deb_url
            deb_url="$(curl -fsSL "$api_url" | grep -o 'https://[^"]*linux-x64\.deb' | head -n1)"
            if [ -z "$deb_url" ]; then
                log "Não consegui achar o .deb do Tabby no último release do GitHub." "ERROR"
                return
            fi
            curl -fsSL "$deb_url" -o /tmp/tabby.deb
            apt-get install -y /tmp/tabby.deb
            rm -f /tmp/tabby.deb
            ;;
        dnf)
            local rpm_url
            rpm_url="$(curl -fsSL "$api_url" | grep -o 'https://[^"]*linux-x64\.rpm' | head -n1)"
            if [ -z "$rpm_url" ]; then
                log "Não consegui achar o .rpm do Tabby no último release do GitHub." "ERROR"
                return
            fi
            dnf install -y "$rpm_url"
            ;;
        *)
            log "Gerenciador de pacotes não reconhecido; pulando Tabby." "WARN"
            return
            ;;
    esac
    log "Tabby instalado." "OK"
}

invoke_terminal_client_install() {
    echo ""
    echo "MobaXterm não existe nativo pra Linux. Escolha uma opção:"
    echo "  1) Bottles + MobaXterm (Wine) - funciona bem, pode sobrar 1 clique manual pra terminar"
    echo "  2) Tabby (ex-Terminus) - cliente de terminal/SSH nativo"
    echo "  0) Pular"
    read -rp "Escolha: " choice
    case "$choice" in
        1) install_moba_via_bottles ;;
        2) install_tabby ;;
        *) log "Pulado." ;;
    esac
}
