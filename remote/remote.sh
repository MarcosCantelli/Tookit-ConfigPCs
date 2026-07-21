#!/usr/bin/env bash
# remote.sh - orquestrador: roda no SEU PC (Linux) e conecta numa máquina remota via SSH
# pra copiar e executar o toolkit certo (Windows ou Linux) por lá.
#
# Requisito na máquina REMOTA:
#   - Linux: servidor SSH (normalmente já vem em qualquer instalação de servidor).
#   - Windows: OpenSSH Server habilitado - ver ../windows-unattend/ (automático na instalação)
#     ou ../tools/Enable-RemoteSsh.ps1 (manual, uma vez).
#
# Autenticação: sem chave, o próprio ssh/scp pergunta usuário/senha na hora (nada fica
# gravado). Com chave, usa ela em vez de senha.
#
# Uso:
#   ./remote.sh <host> <usuario> <windows|linux|linux-dev> [caminho-da-chave-ssh]

set -u

TARGET_HOST="${1:-}"
USERNAME="${2:-}"
TARGET_OS="${3:-}"
KEY_PATH="${4:-}"

if [ -z "$TARGET_HOST" ] || [ -z "$USERNAME" ] || [ -z "$TARGET_OS" ]; then
    echo "Uso: $0 <host> <usuario> <windows|linux|linux-dev> [caminho-da-chave-ssh]"
    exit 1
fi

ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SSH_OPTS=()
if [ -n "$KEY_PATH" ]; then
    if [ ! -f "$KEY_PATH" ]; then
        echo "Chave não encontrada: $KEY_PATH"
        exit 1
    fi
    SSH_OPTS+=("-i" "$KEY_PATH")
fi

run_remote() {
    ssh "${SSH_OPTS[@]}" -t "${USERNAME}@${TARGET_HOST}" "$1"
}

copy_to_remote() {
    scp "${SSH_OPTS[@]}" -r "$1" "${USERNAME}@${TARGET_HOST}:$2"
}

echo "=== Conectando em ${USERNAME}@${TARGET_HOST} (${TARGET_OS}) ==="

case "$TARGET_OS" in
    windows)
        staging="/tmp/toolkit-remote-windows"
        rm -rf "$staging"
        mkdir -p "$staging"
        cp "$ROOT_PATH/setup.ps1" "$staging/"
        [ -f "$ROOT_PATH/Iniciar.bat" ] && cp "$ROOT_PATH/Iniciar.bat" "$staging/"
        cp -r "$ROOT_PATH/modules" "$staging/"
        cp -r "$ROOT_PATH/config" "$staging/"

        echo "Removendo C:\\Toolkit antigo (se existir) na máquina remota..."
        run_remote "if exist C:\\Toolkit rmdir /s /q C:\\Toolkit"

        echo "Copiando toolkit Windows para C:\\Toolkit na máquina remota..."
        copy_to_remote "$staging" "C:/Toolkit"

        echo "Rodando setup.ps1 remotamente (interativo - o menu aparece aqui)..."
        run_remote "powershell -ExecutionPolicy Bypass -File C:\\Toolkit\\setup.ps1"
        ;;
    linux|linux-dev)
        local_folder="$ROOT_PATH/$TARGET_OS"
        if [ ! -d "$local_folder" ]; then
            echo "Pasta '$TARGET_OS' não encontrada em $ROOT_PATH."
            exit 1
        fi

        echo "Removendo /tmp/toolkit antigo (se existir) na máquina remota..."
        run_remote "rm -rf /tmp/toolkit"

        echo "Copiando toolkit '$TARGET_OS' para /tmp/toolkit na máquina remota..."
        copy_to_remote "$local_folder" "/tmp/toolkit"

        echo "Rodando setup.sh remotamente (interativo - o menu aparece aqui; pede senha do sudo se precisar)..."
        run_remote "chmod +x /tmp/toolkit/setup.sh && sudo /tmp/toolkit/setup.sh"
        ;;
    *)
        echo "TARGET_OS inválido: $TARGET_OS (use windows, linux ou linux-dev)"
        exit 1
        ;;
esac

echo "=== Concluído ==="
