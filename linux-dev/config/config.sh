#!/usr/bin/env bash
# config.sh - configuração editável do Dev Kit Linux (desktop: Ubuntu Desktop / Fedora Workstation).

# JDK 21.0.11 (LTS) da Oracle - versão pinada conforme o ambiente em uso.
# Link do archive.oracle.com é fixo por versão, verificado em 2026-07-19.
JDK_TARGZ_URL="https://download.oracle.com/java/21/archive/jdk-21.0.11_linux-x64_bin.tar.gz"

# Maven - verificado em 2026-07-19. Pra atualizar, ver https://maven.apache.org/download.cgi
MAVEN_VERSION="3.9.16"
MAVEN_TARGZ_URL="https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.tar.gz"

# MobaXterm (Windows) pra rodar dentro do Bottles - mesmo link usado no devkit do Windows.
# Link versionado (build 26.4), verificado em 2026-07-19.
MOBAXTERM_INSTALLER_ZIP_URL="https://download.mobatek.net/2642026060332702/MobaXterm_Installer_v26.4.zip"

# Tabby (ex-Terminus) - resolvido dinamicamente via API do GitHub (sempre pega o release
# mais recente), não precisa fixar versão aqui.
TABBY_GITHUB_REPO="Eugeny/tabby"
