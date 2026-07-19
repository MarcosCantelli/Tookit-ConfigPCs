# Toolkit de pós-formatação (Linux - servidor)

Foco em servidor, não estação de trabalho: atualiza o sistema, instala Docker, instala
ferramentas básicas de terminal e configura IP fixo. Nada gráfico (sem Chrome/VLC/etc).

Suporta **Ubuntu Server** (`apt`) e **Oracle Linux** (`dnf`) — o gerenciador é detectado
automaticamente. Tudo via repositório oficial da distro, do Docker (docker.com) ou, no caso
do IP fixo, das próprias ferramentas nativas de rede de cada uma (netplan/NetworkManager).

## Estrutura

```
setup.sh              # entrypoint - rode com sudo
config/config.sh       # lista de ferramentas básicas, editável sem mexer nos módulos
modules/common.sh      # log, checagem de root, detecção de gerenciador de pacotes
modules/system.sh      # atualização de pacotes do sistema
modules/software.sh    # Docker + ferramentas básicas (net-tools, open-vm-tools, htop, tmux...)
modules/network.sh     # configuração de IP fixo
```

## Uso

```bash
sudo ./setup.sh
```

Menu:

```
1) Atualizar sistema (pacotes oficiais da distro)
2) Instalar Docker (Engine + Compose)
3) Instalar ferramentas básicas (net-tools, open-vm-tools, htop, tmux...)
4) Configurar IP fixo
0) Executar tudo (1 -> 2 -> 3) [não inclui IP fixo - é passo separado de propósito]
Q) Sair
```

Logs ficam em `logs/setup_<data>.log`.

## Docker

Instalado a partir do repositório oficial `download.docker.com` (apt para Ubuntu, o repo do
CentOS para Oracle Linux — é o que o próprio Docker recomenda para RHEL-like sem repo
dedicado). Inclui Engine, CLI, containerd, buildx e o plugin do Compose (`docker compose`).

Não adiciono seu usuário ao grupo `docker` automaticamente — isso equivale a acesso root à
máquina, então é uma decisão que fica com você (`usermod -aG docker <usuario>`).

## IP fixo — leia antes de usar

Isso mexe na própria conectividade da máquina. Cuidados já embutidos no script:

- **Ubuntu Server (netplan)**: qualquer config existente que já mencione a interface é
  desativada (renomeada para `.bak`) antes de escrever a nova, pra evitar duas configs
  brigando pela mesma interface. A aplicação usa `netplan try --timeout 30`, que **reverte
  sozinho** se a conexão cair e ninguém confirmar em 30s — ou seja, um IP/gateway errado não
  te tranca pra fora via SSH.
- **Oracle Linux (nmcli/NetworkManager)**: não existe revert automático aqui. Se só tiver
  acesso via SSH, garanta um console de emergência (iLO/iDRAC/console do provedor de nuvem)
  antes de aplicar.

Em ambos os casos o script sempre mostra os dados digitados e pede confirmação antes de
aplicar.

## O que ficou de fora (e por quê)

- **Nada gráfico** (Chrome, VLC, etc.) — é ambiente de servidor.
- **Office / ativação de licença** — não fazem sentido nesse contexto.
- **Arch/pacman** — não é usado nos seus servidores (Ubuntu Server / Oracle Linux), então não
  foi implementado agora.

## Observações

- Nunca testamos isso numa máquina de verdade ainda — vale validar numa VM de teste
  (Ubuntu Server e Oracle Linux) antes de usar em servidor real, principalmente a parte de
  IP fixo.
