# Toolkit de pós-formatação (Windows)

Automatiza as tarefas que se repetem depois de instalar o Windows numa máquina de cliente:
atualização de drivers pelo utilitário oficial do fabricante, instalação de programas básicos,
instalação do Microsoft 365 Apps e ativação do Windows.

> Esta é a versão **template/pública** do projeto: não depende de nenhum storage nem
> credencial privada. Tudo aqui usa apenas fontes oficiais (winget, sites dos próprios
> fabricantes, CDN da Microsoft).

## Estrutura

```
setup.ps1              # entrypoint - rode como administrador
config/config.json      # dados do Office 365 / ODT, links oficiais de fallback, lista de programas
modules/                 # um arquivo por área (Drivers, Software, Office, Activation)
```

## Configuração inicial

Editar `config/config.json`:
- `office365.odtDownloadUrl`: link atual do Office Deployment Tool
  ([download oficial da Microsoft](https://www.microsoft.com/en-us/download/details.aspx?id=49117) —
  o link do arquivo muda de vez em quando, pegue o mais recente).
- `drivers.dell.dcuDownloadUrl` / `drivers.lenovo.suDownloadUrl`: **opcionais** — só são usados
  como fallback se o `winget` estiver indisponível ou a instalação via winget falhar (o caminho
  normal é `winget install Dell.CommandUpdate` / `Lenovo.SystemUpdate`, que já é automático).
- `drivers.hp.hpiaDownloadUrl`: link atual do HP Image Assistant — este é usado sempre, já que
  não há um id de winget confiável para o HPIA
  (https://ftp.hp.com/pub/caps-softpaq/cmit/HPIA.html — também muda de versão em versão).
- `software`: lista de programas (id do winget) a instalar. Adicionar/remover programas = só editar aqui.

**Ativação do Windows** (`modules\Activation.ps1`) só repete o `slmgr /ato` nativo do Windows,
que puxa sozinho a licença OEM gravada na BIOS/firmware (a edição já vem certa da própria
instalação — não há seleção de chave nem edição aqui). **Nunca adicione um `/skms
<servidor-publico>`** nesse fluxo: isso deixaria de ser "ativação OEM" e viraria contorno de
licenciamento via servidor não autorizado.

## Uso (na máquina do cliente, após instalar o Windows)

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

O script se auto-eleva para administrador e mostra um menu:

```
1) Atualizar drivers (utilitário oficial do fabricante)
2) Instalar programas básicos (Chrome, Acrobat, WinRAR, VLC)
3) Instalar Microsoft 365 Apps (direto da Microsoft)
4) Ativar Windows
0) Executar tudo
Q) Sair
```

Logs de cada execução ficam em `logs\setup_<data>.log`.

## Observações importantes

- **Drivers**: só usa o utilitário oficial do fabricante detectado (Dell Command | Update,
  Lenovo System Update, HP Image Assistant). Se a máquina não for de nenhum desses três, o
  script avisa e não faz nada — sem fallback alternativo.
- **Programas básicos**: instalados via `winget` (gerenciador oficial da Microsoft).
- **Microsoft 365 Apps**: baixa direto da CDN oficial da Microsoft; o cliente precisa logar com
  a conta Microsoft 365 depois para ativar.
- **IDs de pacote do winget e switches de CLI dos utilitários de fabricante mudam com o tempo.**
  Se algum passo falhar, o log vai indicar o comando/id que não funcionou — pode ser necessário
  atualizar o id/switch conforme a versão mais recente do fabricante.

## Estendendo (uso privado)

Quem quiser adicionar instalação de Office 2007/2016 a partir de um storage próprio (SMB) pode
recriar um módulo `Storage.ps1` para buscar o instalador e uma credencial cifrada (ver
`ConvertTo-SecureString -Key` para uma chave AES portátil entre máquinas). Essa parte foi
deixada de fora deste template propositalmente, por depender de infraestrutura e credenciais
privadas de cada um.
