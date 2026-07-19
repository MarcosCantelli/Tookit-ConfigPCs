# Generate-Credential.ps1
# Rode este script UMA VEZ (na sua máquina de confiança, não na do cliente) para gerar:
#   - config\aes.key                 (chave AES-256 aleatória)
#   - config\storage_credential.xml  (usuário/senha do storage, cifrados com essa chave)
#
# Esses dois arquivos, juntos, permitem decifrar a senha - trate-os como a própria senha.
# Recomendação: crie no NAS/servidor uma conta de serviço SOMENTE LEITURA, restrita apenas
# à pasta de instaladores, em vez de reaproveitar sua conta pessoal/admin do NAS.
#
# Depois de gerado, copie a pasta config\ inteira (aes.key + storage_credential.xml + config.json)
# para o pendrive/repo privado usado nas máquinas dos clientes.

$ErrorActionPreference = "Stop"

$rootPath = Split-Path -Parent $PSScriptRoot
$configDir = Join-Path $rootPath "config"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$keyPath = Join-Path $configDir "aes.key"
$credPath = Join-Path $configDir "storage_credential.xml"

if ((Test-Path $keyPath) -or (Test-Path $credPath)) {
    $overwrite = Read-Host "Já existe uma credencial gerada. Sobrescrever? (s/N)"
    if ($overwrite -ne "s") {
        Write-Host "Cancelado."
        exit
    }
}

$username = Read-Host "Usuário de serviço (ex: DOMINIO\svc-softwares ou usuário local do NAS)"
$securePassword = Read-Host "Senha" -AsSecureString

# Chave AES-256 (32 bytes) aleatória - independente de usuário/máquina.
$aesKey = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($aesKey)
[System.IO.File]::WriteAllBytes($keyPath, $aesKey)

$encryptedPassword = ConvertFrom-SecureString -SecureString $securePassword -Key $aesKey

[PSCustomObject]@{
    Username          = $username
    EncryptedPassword = $encryptedPassword
} | Export-Clixml -Path $credPath

Write-Host ""
Write-Host "Gerado com sucesso:" -ForegroundColor Green
Write-Host "  $keyPath"
Write-Host "  $credPath"
Write-Host ""
Write-Host "Guarde esses dois arquivos com cuidado - juntos eles decifram a senha do storage." -ForegroundColor Yellow
