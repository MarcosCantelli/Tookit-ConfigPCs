# Office.ps1
# Três caminhos possíveis, decididos pela versão escolhida no menu:
#   - 2007 / 2016 -> busca o zip licenciado no storage próprio (Storage.ps1), extrai e instala.
#   - 365          -> baixa o Office Deployment Tool oficial da Microsoft e instala Click-to-Run.
#                      Ativação por conta Microsoft 365 fica por conta do cliente, depois.

function Invoke-LegacyOfficeInstall {
    param(
        [Parameter(Mandatory = $true)][string]$RootPath,
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)][ValidateSet("2007", "2016")][string]$Version
    )

    $zipName = if ($Version -eq "2007") { $Config.storage.office2007Zip } else { $Config.storage.office2016Zip }
    if (-not $zipName) {
        Write-Log "config.json não tem storage.office${Version}Zip definido." "ERROR"
        return
    }

    $workDir = Join-Path $env:TEMP "Office$Version"
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null

    try {
        $localZip = Copy-FromStorage -RootPath $RootPath -Config $Config -FileName $zipName -DestinationDir $workDir
    }
    catch {
        Write-Log "Falha ao obter o instalador do storage: $($_.Exception.Message)" "ERROR"
        return
    }

    $extractDir = Join-Path $workDir "extracted"
    Write-Log "Extraindo $localZip ..."
    Expand-Archive -Path $localZip -DestinationPath $extractDir -Force

    $setupExe = Get-ChildItem -Path $extractDir -Filter "setup.exe" -Recurse | Select-Object -First 1
    if (-not $setupExe) {
        Write-Log "setup.exe não encontrado dentro do zip do Office $Version." "ERROR"
        return
    }

    $configXml = Get-ChildItem -Path $extractDir -Filter "config.xml" -Recurse | Select-Object -First 1

    Write-Log "Instalando Office $Version (silencioso)..."
    if ($configXml) {
        Start-Process -FilePath $setupExe.FullName -ArgumentList "/config", "`"$($configXml.FullName)`"" -Wait -NoNewWindow
    }
    else {
        Write-Log "config.xml não encontrado no pacote; tentando /quiet /norestart como alternativa." "WARN"
        Start-Process -FilePath $setupExe.FullName -ArgumentList "/quiet", "/norestart" -Wait -NoNewWindow
    }

    Write-Log "Office $Version instalado (licença já embutida no pacote do storage)." "OK"
}

function Invoke-Office365Install {
    param(
        [Parameter(Mandatory = $true)][string]$RootPath,
        [Parameter(Mandatory = $true)]$Config
    )

    $odtUrl = $Config.office365.odtDownloadUrl
    if (-not $odtUrl -or $odtUrl -like "*<*>*") {
        Write-Log "config.json -> office365.odtDownloadUrl não configurado. Pegue o link atual em https://www.microsoft.com/en-us/download/details.aspx?id=49117" "ERROR"
        return
    }

    $workDir = Join-Path $env:TEMP "ODT"
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    $odtInstaller = Join-Path $workDir "odtsetup.exe"

    Write-Log "Baixando Office Deployment Tool (oficial Microsoft)..."
    Invoke-WebRequest -Uri $odtUrl -OutFile $odtInstaller -UseBasicParsing

    Write-Log "Extraindo Office Deployment Tool..."
    Start-Process -FilePath $odtInstaller -ArgumentList "/quiet", "/extract:$workDir" -Wait -NoNewWindow

    $setupExe = Join-Path $workDir "setup.exe"
    if (-not (Test-Path $setupExe)) {
        Write-Log "setup.exe do ODT não encontrado em $workDir." "ERROR"
        return
    }

    $productId = $Config.office365.productId
    $language = $Config.office365.language
    $channel = $Config.office365.channel

    $configXmlContent = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="$channel">
    <Product ID="$productId">
      <Language ID="$language" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="0" />
</Configuration>
"@
    $configXmlPath = Join-Path $workDir "configuration.xml"
    Set-Content -Path $configXmlPath -Value $configXmlContent -Encoding UTF8

    Write-Log "Instalando Microsoft 365 Apps (Click-to-Run, direto da CDN da Microsoft)..."
    Start-Process -FilePath $setupExe -ArgumentList "/configure", "`"$configXmlPath`"" -Wait -NoNewWindow

    Write-Log "Office 365 instalado. Peça para o cliente abrir qualquer app do Office e logar com a conta Microsoft 365 para ativar." "OK"
}

function Invoke-OfficeInstall {
    param(
        [Parameter(Mandatory = $true)][string]$RootPath,
        [Parameter(Mandatory = $true)]$Config
    )

    Write-Host ""
    Write-Host "Qual versão do Office instalar?"
    Write-Host "  1) Office 2007 (storage próprio)"
    Write-Host "  2) Office 2016 (storage próprio)"
    Write-Host "  3) Microsoft 365 (direto da Microsoft)"
    $choice = Read-Host "Escolha"

    switch ($choice) {
        "1" { Invoke-LegacyOfficeInstall -RootPath $RootPath -Config $Config -Version "2007" }
        "2" { Invoke-LegacyOfficeInstall -RootPath $RootPath -Config $Config -Version "2016" }
        "3" { Invoke-Office365Install -RootPath $RootPath -Config $Config }
        default { Write-Log "Opção inválida." "WARN" }
    }
}
