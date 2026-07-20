# DevKit.ps1
# Kit de ferramentas de desenvolvimento: Git, VSCode, Java (Oracle JDK), Maven, Node.js,
# WSL com Oracle Linux, Python, MobaXterm e Visual Studio Community.

function Install-DevGit {
    Install-WingetPackage -Id "Git.Git" -Name "Git"
}

function Install-DevVSCode {
    Install-WingetPackage -Id "Microsoft.VisualStudioCode" -Name "Visual Studio Code"
}

function Install-DevJavaJdk {
    param([Parameter(Mandatory = $true)]$Config)

    $url = $Config.devkit.jdk.windowsMsiUrl
    if (-not $url -or $url -like "*<*>*") {
        Write-Log "config.json -> devkit.jdk.windowsMsiUrl não configurado." "ERROR"
        return
    }

    $workDir = Join-Path $env:TEMP "JDK"
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    $installer = Join-Path $workDir "jdk-installer.msi"

    Write-Log "Baixando Oracle JDK ($url)..."
    Invoke-OfficialDownload -Uri $url -OutFile $installer

    Write-Log "Instalando JDK (silencioso)..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$installer`"", "/qn", "/norestart" -Wait -NoNewWindow

    $jdkHome = Get-ChildItem "C:\Program Files\Java" -Directory -Filter "jdk-*" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $jdkHome) {
        Write-Log "JDK instalado, mas não encontrei a pasta em C:\Program Files\Java para configurar o JAVA_HOME. Configure manualmente." "ERROR"
        return
    }

    Set-MachineEnvironmentVariable -Name "JAVA_HOME" -Value $jdkHome.FullName
    Add-ToMachinePath -PathToAdd (Join-Path $jdkHome.FullName "bin")
    Write-Log "JDK instalado e JAVA_HOME configurado ($($jdkHome.FullName))." "OK"
}

function Install-DevMaven {
    param([Parameter(Mandatory = $true)]$Config)

    $url = $Config.devkit.maven.windowsZipUrl
    if (-not $url -or $url -like "*<*>*") {
        Write-Log "config.json -> devkit.maven.windowsZipUrl não configurado." "ERROR"
        return
    }

    $installDir = "C:\Program Files\Apache"
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null

    $workDir = Join-Path $env:TEMP "Maven"
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    $zipFile = Join-Path $workDir "maven.zip"

    Write-Log "Baixando Maven ($url)..."
    Invoke-OfficialDownload -Uri $url -OutFile $zipFile

    Write-Log "Extraindo Maven para $installDir ..."
    Expand-Archive -Path $zipFile -DestinationPath $installDir -Force

    $mavenHome = Get-ChildItem $installDir -Directory -Filter "apache-maven-*" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $mavenHome) {
        Write-Log "Maven extraído, mas não encontrei a pasta apache-maven-* em $installDir para configurar o MAVEN_HOME." "ERROR"
        return
    }

    Set-MachineEnvironmentVariable -Name "MAVEN_HOME" -Value $mavenHome.FullName
    Add-ToMachinePath -PathToAdd (Join-Path $mavenHome.FullName "bin")
    Write-Log "Maven instalado e MAVEN_HOME configurado ($($mavenHome.FullName))." "OK"
}

function Install-DevNodeJs {
    Install-WingetPackage -Id "OpenJS.NodeJS.LTS" -Name "Node.js LTS"
}

function Install-DevPython {
    param([Parameter(Mandatory = $true)]$Config)

    $wingetId = $Config.devkit.python.wingetId
    if (-not $wingetId) { $wingetId = "Python.Python.3.14" }
    Install-WingetPackage -Id $wingetId -Name "Python"
}

function Install-DevWslOracleLinux {
    param([Parameter(Mandatory = $true)]$Config)

    $distroName = $Config.devkit.wsl.distroName
    if (-not $distroName) { $distroName = "OracleLinux_9_1" }

    $wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if (-not $wsl) {
        Write-Log "wsl.exe não encontrado nesse Windows. Pulei a instalação do WSL." "ERROR"
        return
    }

    Write-Log "Instalando WSL com $distroName (pode pedir reinício se o WSL ainda não estava habilitado)..."
    Start-Process -FilePath "wsl.exe" -ArgumentList "--install", "-d", $distroName -Wait -NoNewWindow

    Write-Log "WSL/$distroName instalado. No primeiro uso, o Windows abre o terminal da distro pra você criar o usuário Linux (isso é do próprio WSL, não dá pra pular)." "OK"
    Write-Log "Depois de criar o usuário, rode 'wsl -d $distroName -- sudo dnf -y update' pra deixar os pacotes atualizados." "WARN"
}

function Install-DevMobaXterm {
    param([Parameter(Mandatory = $true)]$Config)

    $url = $Config.devkit.mobaXterm.installerZipUrl
    if (-not $url -or $url -like "*<*>*") {
        Write-Log "config.json -> devkit.mobaXterm.installerZipUrl não configurado. Pegue o link atual em https://mobaxterm.mobatek.net/download-home-edition.html" "ERROR"
        return
    }

    $workDir = Join-Path $env:TEMP "MobaXterm"
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    $zipFile = Join-Path $workDir "mobaxterm.zip"

    Write-Log "Baixando MobaXterm (instalável, não portable)..."
    Invoke-OfficialDownload -Uri $url -OutFile $zipFile

    Write-Log "Extraindo..."
    Expand-Archive -Path $zipFile -DestinationPath $workDir -Force

    $msi = Get-ChildItem -Path $workDir -Filter "*.msi" -Recurse | Select-Object -First 1
    if (-not $msi) {
        Write-Log "Não encontrei o .msi do MobaXterm dentro do zip baixado." "ERROR"
        return
    }

    Write-Log "Instalando MobaXterm (silencioso)..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$($msi.FullName)`"", "/qn", "/norestart" -Wait -NoNewWindow
    Write-Log "MobaXterm instalado." "OK"
}

function Install-DevVisualStudio2026 {
    Write-Log "Instalando Visual Studio Community 2026 (isso demora bastante, é instalador grande)..."
    if (-not (Test-Winget)) { return }

    $args = @(
        "install", "--exact", "--id", "Microsoft.VisualStudio.Community",
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--override", "--quiet --wait --norestart"
    )
    $proc = Start-Process -FilePath "winget.exe" -ArgumentList $args -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -eq 0) {
        Write-Log "Visual Studio Community 2026 instalado." "OK"
    }
    else {
        Write-Log "Falha ao instalar o Visual Studio (código $($proc.ExitCode))." "ERROR"
    }
}

function Invoke-DevKitInstall {
    param([Parameter(Mandatory = $true)]$Config)

    Write-Host ""
    Write-Host "=== Dev Kit ==="
    Write-Host " 1) Git"
    Write-Host " 2) Visual Studio Code"
    Write-Host " 3) Java JDK 21.0.11 (Oracle) + JAVA_HOME"
    Write-Host " 4) Maven + MAVEN_HOME"
    Write-Host " 5) Node.js LTS"
    Write-Host " 6) Python"
    Write-Host " 7) WSL com Oracle Linux"
    Write-Host " 8) MobaXterm (instalável)"
    Write-Host " 9) Visual Studio Community 2026"
    Write-Host " 0) Tudo"
    $choice = Read-Host "Escolha"

    switch ($choice) {
        "1" { Install-DevGit }
        "2" { Install-DevVSCode }
        "3" { Install-DevJavaJdk -Config $Config }
        "4" { Install-DevMaven -Config $Config }
        "5" { Install-DevNodeJs }
        "6" { Install-DevPython -Config $Config }
        "7" { Install-DevWslOracleLinux -Config $Config }
        "8" { Install-DevMobaXterm -Config $Config }
        "9" { Install-DevVisualStudio2026 }
        "0" {
            Install-DevGit
            Install-DevVSCode
            Install-DevJavaJdk -Config $Config
            Install-DevMaven -Config $Config
            Install-DevNodeJs
            Install-DevPython -Config $Config
            Install-DevWslOracleLinux -Config $Config
            Install-DevMobaXterm -Config $Config
            Install-DevVisualStudio2026
        }
        default { Write-Log "Opção inválida." "WARN" }
    }
}
