# setup.ps1
# Entrypoint do toolkit de pós-formatação. Rodar como administrador (o script se auto-eleva).
#
#   powershell -ExecutionPolicy Bypass -File setup.ps1

$RootPath = $PSScriptRoot

. (Join-Path $RootPath "modules\Common.ps1")

Assert-Admin -ScriptPath $MyInvocation.MyCommand.Path
Initialize-Logging -RootPath $RootPath

. (Join-Path $RootPath "modules\Drivers.ps1")
. (Join-Path $RootPath "modules\Software.ps1")
. (Join-Path $RootPath "modules\Office.ps1")
. (Join-Path $RootPath "modules\Activation.ps1")

function Show-Menu {
    Write-Host ""
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host " Toolkit de pós-formatação" -ForegroundColor Cyan
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host " 1) Atualizar drivers (utilitário oficial do fabricante)"
    Write-Host " 2) Instalar programas básicos (Chrome, Acrobat, WinRAR, VLC)"
    Write-Host " 3) Instalar Microsoft 365 Apps (direto da Microsoft)"
    Write-Host " 4) Ativar Windows"
    Write-Host " 0) Executar tudo (1 -> 2 -> 3 -> 4)"
    Write-Host " Q) Sair"
    Write-Host "=========================================================" -ForegroundColor Cyan
}

function Invoke-All {
    param([Parameter(Mandatory = $true)]$Config)

    Invoke-DriverUpdate -Config $Config
    Invoke-SoftwareInstall -Config $Config
    Invoke-OfficeInstall -RootPath $RootPath -Config $Config
    Invoke-WindowsActivation -RootPath $RootPath
}

try {
    $config = Get-ProjectConfig -RootPath $RootPath
}
catch {
    Write-Log "Erro ao carregar config.json: $($_.Exception.Message)" "ERROR"
    exit 1
}

do {
    Show-Menu
    $choice = Read-Host "Escolha uma opção"

    switch ($choice) {
        "1" { Invoke-DriverUpdate -Config $config }
        "2" { Invoke-SoftwareInstall -Config $config }
        "3" { Invoke-OfficeInstall -RootPath $RootPath -Config $config }
        "4" { Invoke-WindowsActivation -RootPath $RootPath }
        "0" { Invoke-All -Config $config }
        "q" { Write-Log "Encerrando." }
        "Q" { Write-Log "Encerrando." }
        default { Write-Host "Opção inválida." -ForegroundColor Yellow }
    }
} while ($choice -ne "q" -and $choice -ne "Q")
