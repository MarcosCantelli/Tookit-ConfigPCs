# Activation.ps1
# Ativação de licença OEM vinculada à BIOS/firmware.
#
# A edição do Windows já vem certa da própria instalação (o técnico usa a ISO/edição correta),
# e o Windows normalmente já tenta ativar sozinho durante a instalação se houver internet.
# Este módulo só REPETE essa ativação nativa (slmgr /ato) para os casos em que isso não
# aconteceu na hora (sem rede durante o setup, etc.) - sem selecionar chave nenhuma e sem
# apontar para servidor de terceiros. Se a máquina tiver a licença OEM gravada na
# BIOS/firmware, o /ato ativa sozinho contra os servidores da própria Microsoft. Se não
# tiver, ele simplesmente falha - não existe fallback via KMS público neste toolkit.

function Invoke-WindowsActivation {
    param([Parameter(Mandatory = $true)][string]$RootPath)

    if (-not (Test-IsAdmin)) {
        Write-Log "Ativação do Windows requer privilégios de administrador." "ERROR"
        return
    }

    $slmgr = Join-Path $env:WINDIR "System32\slmgr.vbs"
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    Write-Log "Windows detectado: $($os.Caption) ($($os.OSArchitecture))"

    Write-Log "Status de ativação atual:"
    & cscript.exe "//nologo" $slmgr "/xpr" 2>&1 | ForEach-Object { Write-Log "  $_" }

    Write-Log "Tentando ativar (licença OEM gravada na BIOS/firmware é detectada automaticamente)..."
    & cscript.exe "//nologo" $slmgr "/ato" 2>&1 | ForEach-Object { Write-Log "  $_" }

    Write-Log "Status após a tentativa:"
    & cscript.exe "//nologo" $slmgr "/xpr" 2>&1 | ForEach-Object { Write-Log "  $_" }

    Write-Log "Se não ativou: a máquina provavelmente não tem uma licença OEM genuína gravada na BIOS/firmware - nesse caso é preciso uma chave/licença real, este toolkit não tenta contornar isso." "WARN"
}
