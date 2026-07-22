# Execução remota

Roda o toolkit (Windows, `linux/` ou `linux-dev/`) numa máquina remota via SSH, direto do
seu PC — sem precisar levar pendrive. Funciona tanto se o seu PC (o "controlador") for
Windows (`remote.ps1`) quanto Linux (`remote.sh`); o alvo remoto também pode ser Windows ou
Linux, em qualquer combinação.

## Pré-requisito na máquina de destino (a que vai receber o toolkit)

- **Linux**: já tem servidor SSH normalmente (padrão em qualquer instalação de servidor).
- **Windows**: precisa do **OpenSSH Server** habilitado (não vem por padrão numa instalação
  limpa). Duas formas — ver [`../windows-unattend/`](../windows-unattend/):
  1. Automático, direto na instalação, via `autounattend.xml` (recomendado a longo prazo).
  2. Manual, rodando `../tools/Enable-RemoteSsh.ps1` localmente uma vez.

## Uso

**Do Windows:**
```powershell
.\remote.ps1 -TargetHost 192.168.1.50 -Username tecnico -TargetOs windows
.\remote.ps1 -TargetHost 192.168.1.60 -Username root -TargetOs linux -KeyPath C:\chaves\id_ed25519
.\remote.ps1 -TargetHost 192.168.1.70 -Username marcos -TargetOs linux-dev
```

**Do Linux:**
```bash
./remote.sh 192.168.1.50 tecnico windows
./remote.sh 192.168.1.60 root linux ~/.ssh/id_ed25519
./remote.sh 192.168.1.70 marcos linux-dev
```

`TargetOs` (ou o 3º argumento no `.sh`) é `windows`, `linux` (servidor) ou `linux-dev`
(estação de trabalho de dev).

## Autenticação

Se você não passar `-KeyPath` (nem o 4º argumento no `.sh`), o script **pergunta na hora**
se quer usar senha ou chave SSH:

- **Senha**: o próprio `ssh`/`scp` pergunta a senha interativamente. Nada fica gravado em
  lugar nenhum.
- **Chave SSH**: o script pergunta o caminho da chave privada.

Se preferir pular a pergunta (ex: pra automatizar), já passe `-KeyPath <caminho>` / o 4º
argumento direto.

### Erro comum: "Permission denied (publickey)"

Se a máquina remota estiver configurada pra **só aceitar chave** (`PasswordAuthentication
no` no `sshd_config` - comum em servidores mais hardened), escolher "senha" nem chega a
pedir a senha - o servidor recusa antes. Nesse caso: ou usa uma chave já autorizada
(`authorized_keys` do usuário na máquina remota), ou habilita senha no servidor primeiro:
```bash
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

## O que acontece por baixo dos panos

1. Copia a pasta certa do toolkit pra máquina remota via `scp` (`C:\Toolkit` no Windows,
   `/tmp/toolkit` no Linux — qualquer cópia anterior é removida antes, pra garantir que é
   sempre a versão atual).
2. Roda o `setup.ps1`/`setup.sh` remotamente via `ssh -t` (aloca um terminal, então o menu
   interativo aparece normalmente aqui no seu terminal, como se você estivesse local).

## Sobre Ansible

Dava pra fazer isso via Ansible também (foi cogitado), mas pra rodar um script interativo
numa máquina de cada vez, SSH direto já resolve com menos dependência (só precisa do
cliente OpenSSH, que tanto Windows 10/11 quanto qualquer Linux já trazem). Se um dia surgir
a necessidade de rodar em várias máquinas de uma vez de forma não-interativa (ex: só rodar
"atualizar drivers" em 20 máquinas em paralelo, sem menu), aí sim vale a pena montar um
playbook - mas isso é um uso bem diferente do que existe hoje (interativo, uma máquina por
vez).

## Observações

- Nunca testamos isso numa situação real ainda — vale validar com uma máquina de teste
  antes de usar em produção.
- No alvo Windows, a conexão SSH cai direto num shell `cmd`/PowerShell padrão do usuário
  conectado - os comandos usados aqui (`rmdir`, `if exist`) são sintaxe de `cmd.exe`, que é
  o shell padrão do OpenSSH Server no Windows.
