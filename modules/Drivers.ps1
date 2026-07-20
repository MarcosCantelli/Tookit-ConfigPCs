# Drivers.ps1
# Atualização de drivers usando SOMENTE o utilitário oficial de cada fabricante.
# Nenhum download de driver "solto"/terceiro é feito aqui — cada fabricante decide o que instalar.

function Install-DellCommandUpdateDirect {
    param([Parameter(Mandatory = $true)]$Config)

    $url = $Config.drivers.dell.dcuDownloadUrl
    if (-not $url -or $url -like "*<*>*") {
        Write-Log "winget indisponível/falhou e config.json -> drivers.dell.dcuDownloadUrl não está configurado." "ERROR"
        Write-Log "Pegue o link mais recente em https://www.dell.com/support/kbdoc/pt-br/000177325/dell-command-update" "WARN"
        return $false
    }

    $workDir = Join-Path $env:TEMP "DCU"
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    $installer = Join-Path $workDir "dcu-installer.exe"

    Write-Log "Baixando Dell Command | Update de $url ..."
    Invoke-OfficialDownload -Uri $url -OutFile $installer

    Write-Log "Instalando Dell Command | Update (silencioso)..."
    Start-Process -FilePath $installer -ArgumentList "/s" -Wait -NoNewWindow
    return $true
}

function Invoke-DellDriverUpdate {
    param([Parameter(Mandatory = $true)]$Config)

    Write-Log "Fabricante detectado: Dell"

    if (-not (Get-Package -Name "Dell Command | Update*" -ErrorAction SilentlyContinue)) {
        $installedViaWinget = $false
        if (Test-Winget) {
            $exitCode = Install-WingetPackage -Id "Dell.CommandUpdate" -Name "Dell Command | Update"
            $installedViaWinget = ($exitCode -eq 0)
        }
        if (-not $installedViaWinget) {
            Write-Log "winget indisponível ou falhou; baixando o instalador oficial direto da Dell." "WARN"
            Install-DellCommandUpdateDirect -Config $Config | Out-Null
        }
    }
    else {
        Write-Log "Dell Command | Update já está instalado."
    }

    $dcuCli = Get-ChildItem "C:\Program Files*\Dell\CommandUpdate\dcu-cli.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $dcuCli) {
        Write-Log "dcu-cli.exe não encontrado após a instalação. Abra o Dell Command Update manualmente uma vez." "ERROR"
        return
    }

    Write-Log "Buscando atualizações (dcu-cli /scan)..."
    Start-Process -FilePath $dcuCli.FullName -ArgumentList "/scan" -Wait -NoNewWindow

    Write-Log "Aplicando atualizações (dcu-cli /applyUpdates)..."
    Start-Process -FilePath $dcuCli.FullName -ArgumentList "/applyUpdates", "-reboot=disable" -Wait -NoNewWindow

    Write-Log "Dell Command | Update finalizado. Reinicie a máquina quando possível." "OK"
}

function Install-LenovoSystemUpdateDirect {
    param([Parameter(Mandatory = $true)]$Config)

    $url = $Config.drivers.lenovo.suDownloadUrl
    if (-not $url -or $url -like "*<*>*") {
        Write-Log "winget indisponível/falhou e config.json -> drivers.lenovo.suDownloadUrl não está configurado." "ERROR"
        Write-Log "Pegue o link mais recente em https://support.lenovo.com/br/pt/downloads/ds012808" "WARN"
        return $false
    }

    $workDir = Join-Path $env:TEMP "LenovoSU"
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    $installer = Join-Path $workDir "su-installer.exe"

    Write-Log "Baixando Lenovo System Update de $url ..."
    Invoke-OfficialDownload -Uri $url -OutFile $installer

    Write-Log "Instalando Lenovo System Update (silencioso)..."
    Start-Process -FilePath $installer -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait -NoNewWindow
    return $true
}

function Invoke-LenovoDriverUpdate {
    param([Parameter(Mandatory = $true)]$Config)

    Write-Log "Fabricante detectado: Lenovo"

    if (-not (Get-Package -Name "Lenovo System Update*" -ErrorAction SilentlyContinue)) {
        $installedViaWinget = $false
        if (Test-Winget) {
            $exitCode = Install-WingetPackage -Id "Lenovo.SystemUpdate" -Name "Lenovo System Update"
            $installedViaWinget = ($exitCode -eq 0)
        }
        if (-not $installedViaWinget) {
            Write-Log "winget indisponível ou falhou; baixando o instalador oficial direto da Lenovo." "WARN"
            Install-LenovoSystemUpdateDirect -Config $Config | Out-Null
        }
    }
    else {
        Write-Log "Lenovo System Update já está instalado."
    }

    $tvsu = Get-ChildItem "C:\Program Files*\Lenovo\System Update\tvsu.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $tvsu) {
        Write-Log "tvsu.exe não encontrado após a instalação. Abra o Lenovo System Update manualmente uma vez." "ERROR"
        return
    }

    Write-Log "Buscando atualizações (tvsu /CM -action=scan)..."
    Start-Process -FilePath $tvsu.FullName -ArgumentList "/CM", "-action=scan" -Wait -NoNewWindow

    Write-Log "Aplicando atualizações (tvsu /CM -action=install)..."
    Start-Process -FilePath $tvsu.FullName -ArgumentList "/CM", "-action=install" -Wait -NoNewWindow

    Write-Log "Lenovo System Update finalizado. Reinicie a máquina quando possível." "OK"
}

function Invoke-HPDriverUpdate {
    param([Parameter(Mandatory = $true)]$Config)

    Write-Log "Fabricante detectado: HP"

    $hpiaUrl = $Config.drivers.hp.hpiaDownloadUrl
    if (-not $hpiaUrl -or $hpiaUrl -like "*<*>*") {
        Write-Log "URL do HP Image Assistant não configurada em config.json (drivers.hp.hpiaDownloadUrl)." "ERROR"
        Write-Log "Pegue o link mais recente em https://ftp.hp.com/pub/caps-softpaq/cmit/HPIA.html (versão muda com frequência)." "WARN"
        return
    }

    $workDir = Join-Path $env:TEMP "HPIA"
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    $installer = Join-Path $workDir "hpia-installer.exe"

    Write-Log "Baixando HP Image Assistant de $hpiaUrl ..."
    Invoke-OfficialDownload -Uri $hpiaUrl -OutFile $installer

    Write-Log "Extraindo HP Image Assistant..."
    Start-Process -FilePath $installer -ArgumentList "/s", "/e", "/f", $workDir -Wait -NoNewWindow

    $hpia = Get-ChildItem -Path $workDir -Filter "HPImageAssistant.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $hpia) {
        Write-Log "HPImageAssistant.exe não encontrado após extração em $workDir." "ERROR"
        return
    }

    $reportFolder = Join-Path $workDir "Report"
    Write-Log "Rodando HP Image Assistant (Analyze + Install, silencioso)..."
    Start-Process -FilePath $hpia.FullName -ArgumentList @(
        "/Operation:Analyze",
        "/Action:Install",
        "/Category:Drivers,Firmware",
        "/Selection:All",
        "/Silent",
        "/ReportFolder:$reportFolder"
    ) -Wait -NoNewWindow

    Write-Log "HP Image Assistant finalizado. Relatório em $reportFolder. Reinicie a máquina quando possível." "OK"
}

function Invoke-DriverUpdate {
    param([Parameter(Mandatory = $true)]$Config)

    $manufacturer = Get-Manufacturer
    switch ($manufacturer) {
        "Dell"    { Invoke-DellDriverUpdate -Config $Config }
        "Lenovo"  { Invoke-LenovoDriverUpdate -Config $Config }
        "HP"      { Invoke-HPDriverUpdate -Config $Config }
        default {
            Write-Log "Fabricante '$manufacturer' não reconhecido (nem Dell, Lenovo ou HP). Nenhuma ação de driver será executada." "WARN"
        }
    }
}
