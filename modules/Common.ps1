# Common.ps1
# Funções compartilhadas: elevação de admin, log, detecção de fabricante, checagem do winget.

$script:LogPath = $null

function Initialize-Logging {
    param([string]$RootPath)

    $logDir = Join-Path $RootPath "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:LogPath = Join-Path $logDir "setup_$timestamp.log"
    Write-Log "===== Sessão iniciada ====="
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "OK")][string]$Level = "INFO"
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message

    $color = switch ($Level) {
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        "OK"    { "Green" }
        default { "Gray" }
    }
    Write-Host $line -ForegroundColor $color

    if ($script:LogPath) {
        Add-Content -Path $script:LogPath -Value $line -Encoding UTF8
    }
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Admin {
    param([string]$ScriptPath)

    if (-not (Test-IsAdmin)) {
        Write-Host "Privilégios de administrador são necessários. Reabrindo elevado..." -ForegroundColor Yellow
        $psi = @{
            FilePath     = "powershell.exe"
            ArgumentList = @("-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$ScriptPath`"")
            Verb         = "RunAs"
        }
        Start-Process @psi
        exit
    }
}

function Get-Manufacturer {
    $rawManufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
    if (-not $rawManufacturer) { return "Unknown" }

    switch -Regex ($rawManufacturer) {
        "Dell"                     { return "Dell" }
        "Lenovo"                   { return "Lenovo" }
        "Hewlett-Packard|HP"       { return "HP" }
        default                    { return "Unknown" }
    }
}

function Test-Winget {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Log "winget não encontrado. Instale o 'App Installer' pela Microsoft Store (fonte oficial) e rode novamente." "ERROR"
        return $false
    }
    return $true
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [string]$Name = $Id
    )

    Write-Log "Instalando $Name (winget id: $Id)..."
    $args = @(
        "install", "--exact", "--id", $Id,
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--disable-interactivity"
    )
    $proc = Start-Process -FilePath "winget.exe" -ArgumentList $args -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -eq 0) {
        Write-Log "$Name instalado com sucesso." "OK"
    }
    else {
        Write-Log "Falha ao instalar $Name (código $($proc.ExitCode)). Verifique o id do pacote no winget." "ERROR"
    }
    return $proc.ExitCode
}

function Get-ProjectConfig {
    param([string]$RootPath)

    $configFile = Join-Path $RootPath "config\config.json"
    if (-not (Test-Path $configFile)) {
        throw "Arquivo de configuração não encontrado: $configFile"
    }
    return Get-Content -Path $configFile -Raw | ConvertFrom-Json
}
