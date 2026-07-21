# Enable-RemoteSsh.ps1
# Bootstrap manual pra máquinas Windows que NÃO foram instaladas com o
# windows-unattend\autounattend.xml. Rode uma vez, localmente, como administrador.
# Depois disso a máquina aceita conexão SSH normalmente (remote\remote.ps1 / remote.sh).

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Rode este script como administrador." -ForegroundColor Red
    exit 1
}

Write-Host "Instalando o OpenSSH Server (componente opcional oficial do Windows)..."
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null

Write-Host "Habilitando e iniciando o serviço sshd..."
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd

if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    Write-Host "Liberando a porta 22 no firewall..."
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" `
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
}

Write-Host "OpenSSH Server pronto. Essa máquina já aceita conexão remota via SSH." -ForegroundColor Green
