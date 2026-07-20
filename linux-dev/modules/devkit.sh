#!/usr/bin/env bash
# devkit.sh - Git, VSCode, Java (Oracle JDK), Maven, Node.js e Python.
# Tudo via repositório oficial (Microsoft, NodeSource endossado pelo próprio Node.js
# Foundation) ou download direto do site do fabricante (Oracle).

install_dev_git() {
    log "Instalando Git..."
    case "$PKG_MANAGER" in
        apt) apt-get install -y git ;;
        dnf) dnf install -y git ;;
        *) log "Gerenciador de pacotes não reconhecido; pulando Git." "WARN"; return ;;
    esac
    log "Git instalado." "OK"
}

install_dev_vscode() {
    if command -v code >/dev/null 2>&1; then
        log "VSCode já instalado - atualizando via gerenciador de pacotes."
        case "$PKG_MANAGER" in
            apt) apt-get install -y code ;;
            dnf) dnf upgrade -y code ;;
        esac
        return
    fi

    log "Instalando VSCode (repositório oficial da Microsoft)..."
    case "$PKG_MANAGER" in
        apt)
            apt-get install -y wget gpg
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft.gpg
            install -D -o root -g root -m 644 /usr/share/keyrings/microsoft.gpg /etc/apt/keyrings/microsoft.gpg
            echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
                > /etc/apt/sources.list.d/vscode.list
            rm -f /usr/share/keyrings/microsoft.gpg
            apt-get update
            apt-get install -y code
            ;;
        dnf)
            rpm --import https://packages.microsoft.com/keys/microsoft.asc
            cat > /etc/yum.repos.d/vscode.repo <<'REPO'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
REPO
            dnf install -y code
            ;;
        *)
            log "Gerenciador de pacotes não reconhecido; pulando VSCode." "WARN"
            return
            ;;
    esac
    log "VSCode instalado." "OK"
}

install_dev_java_jdk() {
    if [ -d /opt/java/jdk-21.0.11 ]; then
        log "JDK 21.0.11 já está em /opt/java/jdk-21.0.11 - pulando download."
    else
        log "Baixando Oracle JDK 21.0.11 ($JDK_TARGZ_URL)..."
        mkdir -p /opt/java
        local tarball="/tmp/jdk-21.0.11.tar.gz"
        curl -fsSL "$JDK_TARGZ_URL" -o "$tarball"
        tar -xzf "$tarball" -C /opt/java
        rm -f "$tarball"
    fi

    local jdk_home
    jdk_home="$(find /opt/java -maxdepth 1 -type d -name 'jdk-21.0.11*' | head -n1)"
    if [ -z "$jdk_home" ]; then
        log "Não encontrei a pasta extraída do JDK em /opt/java." "ERROR"
        return
    fi

    cat > /etc/profile.d/java.sh <<EOF
export JAVA_HOME="$jdk_home"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF
    chmod 644 /etc/profile.d/java.sh
    log "JDK 21.0.11 instalado em $jdk_home. JAVA_HOME configurado em /etc/profile.d/java.sh (vale a partir do próximo login/shell)." "OK"
}

install_dev_maven() {
    local maven_home="/opt/maven/apache-maven-$MAVEN_VERSION"
    if [ -d "$maven_home" ]; then
        log "Maven $MAVEN_VERSION já está em $maven_home - pulando download."
    else
        log "Baixando Maven $MAVEN_VERSION ($MAVEN_TARGZ_URL)..."
        mkdir -p /opt/maven
        local tarball="/tmp/maven.tar.gz"
        curl -fsSL "$MAVEN_TARGZ_URL" -o "$tarball"
        tar -xzf "$tarball" -C /opt/maven
        rm -f "$tarball"
    fi

    cat > /etc/profile.d/maven.sh <<EOF
export MAVEN_HOME="$maven_home"
export PATH="\$MAVEN_HOME/bin:\$PATH"
EOF
    chmod 644 /etc/profile.d/maven.sh
    log "Maven instalado em $maven_home. MAVEN_HOME configurado em /etc/profile.d/maven.sh (vale a partir do próximo login/shell)." "OK"
}

install_dev_nodejs() {
    if command -v node >/dev/null 2>&1; then
        log "Node.js já instalado ($(node --version)) - atualizando via gerenciador de pacotes."
        case "$PKG_MANAGER" in
            apt) apt-get install -y nodejs ;;
            dnf) dnf upgrade -y nodejs ;;
        esac
        return
    fi

    log "Instalando Node.js LTS (repositório oficial NodeSource, endossado pelo Node.js Foundation)..."
    case "$PKG_MANAGER" in
        apt)
            curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
            apt-get install -y nodejs
            ;;
        dnf)
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
            dnf install -y nodejs
            ;;
        *)
            log "Gerenciador de pacotes não reconhecido; pulando Node.js." "WARN"
            return
            ;;
    esac
    log "Node.js instalado ($(node --version))." "OK"
}

install_dev_python() {
    log "Python: verificando o que já vem instalado na distro..."
    if command -v python3 >/dev/null 2>&1; then
        log "python3 já presente ($(python3 --version 2>&1)). Atualizando + garantindo pip/venv..."
    else
        log "python3 não encontrado (incomum nessas distros); instalando."
    fi

    case "$PKG_MANAGER" in
        apt)
            apt-get install -y python3 python3-pip python3-venv
            ;;
        dnf)
            dnf install -y python3 python3-pip
            ;;
        *)
            log "Gerenciador de pacotes não reconhecido; pulando Python." "WARN"
            return
            ;;
    esac
    log "Python pronto ($(python3 --version 2>&1))." "OK"
}

invoke_devkit_base_install() {
    install_dev_git
    install_dev_vscode
    install_dev_java_jdk
    install_dev_maven
    install_dev_nodejs
    install_dev_python
}
