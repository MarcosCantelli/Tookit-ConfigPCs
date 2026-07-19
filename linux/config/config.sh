#!/usr/bin/env bash
# config.sh - configuração editável do toolkit Linux (foco em servidor: Ubuntu Server / Oracle Linux).

# Docker é tratado à parte (precisa adicionar o repositório oficial docker.com antes de
# instalar) - ver modules/software.sh -> install_docker.
INSTALL_DOCKER=true

# Ferramentas básicas de servidor: "nome amigável|pacote apt|pacote dnf"
# Use "--" quando não houver pacote equivalente naquela família.
SOFTWARE_LIST=(
    "net-tools|net-tools|net-tools"
    "open-vm-tools|open-vm-tools|open-vm-tools"
    "htop|htop|htop"
    "tmux|tmux|tmux"
    "vim|vim|vim"
    "curl|curl|curl"
    "wget|wget|wget"
    "git|git|git"
    "unzip|unzip|unzip"
    "traceroute|traceroute|traceroute"
    "dig/nslookup|dnsutils|bind-utils"
)
