#!/usr/bin/env bash
# config.sh - configuração editável do toolkit Linux (sem precisar mexer nos módulos).

# Google Chrome é tratado à parte (precisa adicionar o repositório oficial da Google/RPM
# antes de instalar) - ver modules/software.sh -> install_google_chrome.
INSTALL_CHROME=true

# Lista de programas básicos: "nome amigável|pacote apt|pacote dnf|pacote pacman"
# Use "--" quando não houver pacote oficial equivalente naquela família de distro.
#
# Observações:
#   - Não existe cliente oficial do Adobe Acrobat Reader para Linux há anos; por isso não
#     está na lista (os visualizadores de PDF que já vêm com a distro cobrem o caso de uso).
#   - WinRAR não tem build nativo/oficial para Linux; o equivalente mais próximo com pacote
#     oficial em cada distro é unrar (leitura de .rar) + p7zip (zip/7z), por isso a lista usa
#     esses dois em vez de "WinRAR".
SOFTWARE_LIST=(
    "unrar|unrar|unrar|unrar"
    "p7zip|p7zip-full|p7zip p7zip-plugins|p7zip"
)
