# Toolkit de pós-formatação (Linux)

Equivalente Linux do toolkit Windows: atualiza o sistema/drivers e instala os programas
básicos, usando só repositórios oficiais (da distro, da Google e, no Fedora, RPM Fusion —
repositório recomendado pelo próprio projeto Fedora para pacotes com restrição de
licença/patente, como o VLC).

Suporta Debian/Ubuntu (`apt`), Fedora/RHEL (`dnf`) e Arch (`pacman`) — o gerenciador é
detectado automaticamente.

## Estrutura

```
setup.sh              # entrypoint - rode com sudo
config/config.sh       # lista de programas básicos, editável sem mexer nos módulos
modules/common.sh      # log, checagem de root, detecção de gerenciador de pacotes
modules/drivers.sh     # atualização de pacotes do sistema + driver de GPU (ubuntu-drivers)
modules/software.sh    # Chrome, VLC, unrar, p7zip
```

## Uso

```bash
sudo ./setup.sh
```

Menu:

```
1) Atualizar sistema/drivers (pacotes oficiais da distro)
2) Instalar programas básicos (Chrome, VLC, unrar, p7zip)
0) Executar tudo
Q) Sair
```

Logs ficam em `logs/setup_<data>.log`.

## O que ficou de fora (e por quê)

- **Adobe Acrobat Reader**: não existe cliente oficial pra Linux há anos. Os visualizadores
  de PDF que já vêm com a distro (Evince, Okular, etc.) cobrem o caso de uso.
- **WinRAR**: não tem build nativo/oficial pra Linux. Em vez disso instalamos `unrar`
  (leitura de `.rar`) e `p7zip` (zip/7z), que são os pacotes oficiais equivalentes em cada
  distro.
- **Chrome no Arch**: não está nos repositórios oficiais do Arch, só via AUR (comunidade,
  não oficial) — por isso é pulado nessa distro, com aviso no log.
- **Office / ativação de licença**: não fazem sentido nesse contexto (LibreOffice já vem
  nativo na maioria das distros; não existe "ativação OEM" no Linux).

## Observações

- "Atualizar drivers" no Linux, na prática, é atualizar os pacotes do sistema — o
  kernel/distro já distribuem os drivers via repositório oficial, diferente do Windows
  (que depende de um utilitário separado por fabricante).
- Em Ubuntu/derivados, também rodamos o `ubuntu-drivers autoinstall` (utilitário oficial da
  Canonical) para detectar e instalar o driver de GPU recomendado.
- Nunca testamos isso numa máquina Linux de verdade ainda — vale validar numa VM de cada
  família (Debian/Ubuntu, Fedora, Arch) antes de usar com cliente.
