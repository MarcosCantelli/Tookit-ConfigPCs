# Software.ps1
# Instalação dos programas básicos do dia a dia via winget (fonte oficial).
# A lista de programas vem de config.json -> "software" (adicionar/remover programas ali, sem mexer no código).

function Invoke-SoftwareInstall {
    param([Parameter(Mandatory = $true)]$Config)

    if (-not (Test-Winget)) { return }

    if (-not $Config.software -or $Config.software.Count -eq 0) {
        Write-Log "Nenhum programa configurado em config.json -> software." "WARN"
        return
    }

    foreach ($app in $Config.software) {
        Install-WingetPackage -Id $app.wingetId -Name $app.name
    }

    Write-Log "Instalação de programas básicos concluída." "OK"
}
