# Dev Kit (Linux desktop)

Kit de ferramentas de desenvolvimento pra estação de trabalho Linux (Ubuntu Desktop /
Fedora Workstation). **Separado do toolkit de servidor** em [`../linux/`](../linux/) de
propósito — são contextos diferentes (dev desktop vs. servidor).

## Estrutura

```
setup.sh              # entrypoint - rode com sudo
config/config.sh       # versões/links do JDK, Maven, MobaXterm - editável sem mexer nos módulos
modules/common.sh      # log, checagem de root, detecção de gerenciador de pacotes
modules/devkit.sh      # Git, VSCode, JDK, Maven, Node.js, Python
modules/terminal.sh    # Bottles+MobaXterm ou Tabby (ex-Terminus)
```

## Uso

```bash
sudo ./setup.sh
```

Menu:

```
1) Git
2) VSCode
3) Java JDK 21.0.11 (Oracle) + JAVA_HOME
4) Maven + MAVEN_HOME
5) Node.js LTS (NodeSource)
6) Python (atualiza o que já vem instalado + pip/venv)
7) Terminal tipo MobaXterm (Bottles+MobaXterm ou Tabby)
0) Tudo (1 -> 6, sem o passo 7 - esse é interativo de propósito)
Q) Sair
```

## Detalhes por ferramenta

- **Git / Python**: se já vierem instalados na distro (comum), o script atualiza em vez de
  reinstalar do zero.
- **VSCode**: repositório oficial da Microsoft (`packages.microsoft.com`).
- **Java JDK 21.0.11 (Oracle)**: baixado direto do `download.oracle.com` (mesma versão
  pinada usada no devkit Windows), extraído em `/opt/java/jdk-21.0.11`. `JAVA_HOME` fica
  em `/etc/profile.d/java.sh` (vale a partir do próximo login/shell).
- **Maven**: baixado do `dlcdn.apache.org`, extraído em `/opt/maven/apache-maven-<versão>`.
  `MAVEN_HOME` em `/etc/profile.d/maven.sh`.
- **Node.js LTS**: via NodeSource (`deb.nodesource.com` / `rpm.nodesource.com`) — é o método
  que o próprio Node.js Foundation recomenda na página oficial de downloads pra Linux.
- **MobaXterm não existe nativo pra Linux.** Duas opções no menu 7:
  - **Bottles + MobaXterm**: instala o [Bottles](https://usebottles.com/) (Flatpak/Flathub) e
    tenta automatizar via `bottles-cli` a criação de um bottle + instalação do MobaXterm.exe
    do Windows dentro dele. A CLI do Bottles é relativamente nova e pode variar entre
    versões — não deu pra testar num ambiente real, então se a automação falhar, o script
    avisa e deixa o instalador baixado pra você terminar manualmente pelo Bottles (GUI).
  - **Tabby** (ex-Terminus): cliente de terminal/SSH nativo multiplataforma, mais simples —
    resolvido dinamicamente pela API do GitHub (sempre pega o release mais recente).

## O que ficou de fora (e por quê)

- **WSL**: não se aplica, você já está no Linux.
- **Visual Studio 2026**: é Windows-only (o VSCode já cobre a parte multiplataforma).

## Observações

- Precisa rodar como root (`sudo`) porque mexe em pacotes do sistema, mas as partes de
  usuário (Flatpak/Bottles) rodam como o usuário real que chamou o sudo (`$SUDO_USER`), não
  como root — senão o Bottles ficaria configurado pro usuário `root` em vez do seu usuário.
- Nunca testamos isso numa máquina de verdade ainda — vale validar numa VM (Ubuntu Desktop
  e Fedora Workstation) antes de usar no dia a dia, principalmente a parte do Bottles.
