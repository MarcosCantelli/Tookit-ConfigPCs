# Software.ps1
# Instalação dos programas básicos do dia a dia via winget (fonte oficial).
# A lista de programas vem de config.json -> "software" (adicionar/remover programas ali, sem mexer no código).

function Install-NortonTrial {
    param([Parameter(Mandatory = $true)]$Config)

    if (-not $Config.norton -or $Config.norton.installTrial -ne $true) {
        return
    }

    $url = $Config.norton.trialInstallerUrl
    if (-not $url -or $url -like "*<*>*") {
        Write-Log "config.json -> norton.trialInstallerUrl não configurado." "ERROR"
        Write-Log "Norton não oferece link público de download direto - o link do instalador do trial só aparece depois de fazer o cadastro (sem custo) em https://us.norton.com/downloads. Pegue o link lá e cole no config.json." "WARN"
        return
    }

    $workDir = Join-Path $env:TEMP "Norton"
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    $installer = Join-Path $workDir "NortonSetup.exe"

    Write-Log "Baixando o instalador do Norton 360 (trial)..."
    Invoke-OfficialDownload -Uri $url -OutFile $installer

    Write-Log "Instalando Norton 360 (tentativa silenciosa - não confirmado em ambiente real, o instalador da Norton pode abrir alguma tela mesmo assim)..."
    Start-Process -FilePath $installer -ArgumentList "/silent" -Wait -NoNewWindow

    Write-Log "Norton 360 (trial) instalado. O cliente precisa criar/logar numa conta Norton para ativar o período de teste." "OK"
}

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

    Install-NortonTrial -Config $Config

    Write-Log "Instalação de programas básicos concluída." "OK"
}
