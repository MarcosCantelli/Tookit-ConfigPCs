# Storage.ps1
# Acesso ao compartilhamento SMB (NAS/servidor próprio) que guarda os instaladores do Office 2007/2016.
# Usa uma credencial cifrada com uma chave AES própria (gerada por tools/Generate-Credential.ps1),
# o que permite decifrar em QUALQUER máquina Windows (diferente do DPAPI padrão, que é preso a
# usuário/máquina). Por isso, proteja config/aes.key + config/storage_credential.xml como se
# fossem a própria senha.

function Get-StorageCredential {
    param([Parameter(Mandatory = $true)][string]$RootPath)

    $keyFile = Join-Path $RootPath "config\aes.key"
    $credFile = Join-Path $RootPath "config\storage_credential.xml"

    if (-not (Test-Path $keyFile) -or -not (Test-Path $credFile)) {
        throw "Credencial do storage não configurada. Rode tools\Generate-Credential.ps1 primeiro (gera $keyFile e $credFile)."
    }

    $key = [System.IO.File]::ReadAllBytes($keyFile)
    $cred = Import-Clixml -Path $credFile
    $securePassword = ConvertTo-SecureString -String $cred.EncryptedPassword -Key $key

    return New-Object System.Management.Automation.PSCredential($cred.Username, $securePassword)
}

function Copy-FromStorage {
    param(
        [Parameter(Mandatory = $true)][string]$RootPath,
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)][string]$FileName,
        [Parameter(Mandatory = $true)][string]$DestinationDir
    )

    $sharePath = $Config.storage.sharePath
    if (-not $sharePath) {
        throw "config.json -> storage.sharePath não está definido."
    }

    $credential = Get-StorageCredential -RootPath $RootPath
    $driveLetter = "Z"

    Write-Log "Montando storage $sharePath ..."
    try {
        New-SmbMapping -LocalPath "${driveLetter}:" -RemotePath $sharePath -UserName $credential.UserName `
            -Password $credential.GetNetworkCredential().Password -Persistent $false -ErrorAction Stop | Out-Null
    }
    catch {
        throw "Falha ao montar o storage: $($_.Exception.Message)"
    }

    try {
        $sourceFile = Join-Path "${driveLetter}:" $FileName
        if (-not (Test-Path $sourceFile)) {
            throw "Arquivo '$FileName' não encontrado em $sharePath."
        }

        if (-not (Test-Path $DestinationDir)) {
            New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
        }

        $localFile = Join-Path $DestinationDir $FileName
        Write-Log "Copiando $FileName do storage para $localFile ..."
        Copy-Item -Path $sourceFile -Destination $localFile -Force

        return $localFile
    }
    finally {
        Write-Log "Desmontando storage..."
        Remove-SmbMapping -LocalPath "${driveLetter}:" -Force -ErrorAction SilentlyContinue
    }
}
