# remote.ps1 - orquestrador: roda no SEU PC (Windows) e conecta numa máquina remota via SSH
# (cliente OpenSSH nativo do Windows 10/11) pra copiar e executar o toolkit certo
# (Windows ou Linux) por lá.
#
# Requisito na máquina REMOTA:
#   - Linux: servidor SSH (normalmente já vem em qualquer instalação de servidor).
#   - Windows: OpenSSH Server habilitado - ver ..\windows-unattend\ (automático na instalação)
#     ou ..\tools\Enable-RemoteSsh.ps1 (manual, uma vez).
#
# Autenticação: se não passar -KeyPath, o próprio ssh/scp pergunta usuário/senha na hora
# (nada fica gravado). Se passar -KeyPath, usa a chave SSH em vez de senha.
#
# Uso:
#   .\remote\remote.ps1 -TargetHost 192.168.1.50 -Username tecnico -TargetOs windows
#   .\remote\remote.ps1 -TargetHost 192.168.1.60 -Username root -TargetOs linux -KeyPath C:\chaves\id_ed25519

param(
    [Parameter(Mandatory = $true)][string]$TargetHost,
    [Parameter(Mandatory = $true)][string]$Username,
    [Parameter(Mandatory = $true)][ValidateSet("windows", "linux", "linux-dev")][string]$TargetOs,
    [string]$KeyPath
)

$ErrorActionPreference = "Stop"
$RootPath = Split-Path -Parent $PSScriptRoot

$sshExtraArgs = @()
if ($KeyPath) {
    if (-not (Test-Path $KeyPath)) {
        Write-Host "Chave não encontrada: $KeyPath" -ForegroundColor Red
        exit 1
    }
    $sshExtraArgs += @("-i", $KeyPath)
}

function Invoke-RemoteCommand {
    param([string]$Command)
    & ssh @sshExtraArgs -t "$Username@$TargetHost" $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Comando remoto falhou (código $LASTEXITCODE)."
    }
}

function Copy-ToRemote {
    param([string]$LocalPath, [string]$RemoteDest)
    & scp @sshExtraArgs -r $LocalPath "${Username}@${TargetHost}:${RemoteDest}"
    if ($LASTEXITCODE -ne 0) {
        throw "Cópia via scp falhou (código $LASTEXITCODE)."
    }
}

Write-Host "=== Conectando em $Username@$TargetHost ($TargetOs) ===" -ForegroundColor Cyan

if ($TargetOs -eq "windows") {
    $staging = Join-Path $env:TEMP "toolkit-remote-windows"
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $staging | Out-Null
    Copy-Item (Join-Path $RootPath "setup.ps1") $staging
    Copy-Item (Join-Path $RootPath "Iniciar.bat") $staging -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $RootPath "modules") $staging -Recurse
    Copy-Item (Join-Path $RootPath "config") $staging -Recurse

    Write-Host "Removendo C:\Toolkit antigo (se existir) na máquina remota..."
    Invoke-RemoteCommand "if exist C:\Toolkit rmdir /s /q C:\Toolkit"

    Write-Host "Copiando toolkit Windows para C:\Toolkit na máquina remota..."
    Copy-ToRemote -LocalPath $staging -RemoteDest "C:/Toolkit"

    Write-Host "Rodando setup.ps1 remotamente (interativo - o menu aparece aqui)..."
    Invoke-RemoteCommand "powershell -ExecutionPolicy Bypass -File C:\Toolkit\setup.ps1"
}
else {
    $localFolder = Join-Path $RootPath $TargetOs
    if (-not (Test-Path $localFolder)) {
        throw "Pasta '$TargetOs' não encontrada em $RootPath."
    }

    Write-Host "Removendo /tmp/toolkit antigo (se existir) na máquina remota..."
    Invoke-RemoteCommand "rm -rf /tmp/toolkit"

    Write-Host "Copiando toolkit '$TargetOs' para /tmp/toolkit na máquina remota..."
    Copy-ToRemote -LocalPath $localFolder -RemoteDest "/tmp/toolkit"

    Write-Host "Rodando setup.sh remotamente (interativo - o menu aparece aqui; pede senha do sudo se precisar)..."
    Invoke-RemoteCommand "chmod +x /tmp/toolkit/setup.sh && sudo /tmp/toolkit/setup.sh"
}

Write-Host "=== Concluído ===" -ForegroundColor Green
