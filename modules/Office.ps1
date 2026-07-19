# Office.ps1
# Instalação do Microsoft 365 Apps via Office Deployment Tool oficial da Microsoft (Click-to-Run).
# Ativação por conta Microsoft 365 fica por conta do cliente, depois da instalação.

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

    Invoke-Office365Install -RootPath $RootPath -Config $Config
}
