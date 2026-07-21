# Toolkit de pós-formatação (Windows)

Automatiza as tarefas que se repetem depois de instalar o Windows numa máquina de cliente:
atualização de drivers pelo utilitário oficial do fabricante, instalação de programas básicos,
instalação do Microsoft 365 Apps e ativação do Windows.

> Esta é a versão **template/pública** do projeto: não depende de nenhum storage nem
> credencial privada. Tudo aqui usa apenas fontes oficiais (winget, sites dos próprios
> fabricantes, CDN da Microsoft).
>
> Tem um equivalente para Linux em [`linux/`](linux/) (atualização de pacotes/drivers e
> instalação de programas básicos via repositórios oficiais da distro).
>
> Kit de ferramentas de desenvolvimento (Git, VSCode, JDK, Maven, Node, Python, WSL,
> MobaXterm, VS2026) é o menu **5) Dev Kit** deste script. O equivalente pra estação de
> trabalho Linux está em [`linux-dev/`](linux-dev/) (separado do toolkit de servidor).
>
> Dá pra rodar tudo isso numa máquina remota via SSH, sem levar pendrive — ver
> [`remote/`](remote/) (funciona partindo de um controlador Windows ou Linux, mirando um
> alvo Windows ou Linux). No Windows, o alvo precisa do OpenSSH Server habilitado antes —
> ver [`windows-unattend/`](windows-unattend/) (automático na instalação) ou
> [`tools/Enable-RemoteSsh.ps1`](tools/Enable-RemoteSsh.ps1) (manual).

## Estrutura

```
Iniciar.bat             # atalho - dois cliques já roda com a execution policy certa
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
- `drivers.hp.supportSolutionsFrameworkUrl` / `supportAssistantUrl`: links do HP Support
  Solutions Framework + HP Support Assistant (o HP Image Assistant NÃO serve pra isso — é
  ferramenta de imaging/análise de TI, não atualiza drivers de uma máquina). Não há id de
  winget confiável pra nenhum dos dois; o botão de download do site da HP esconde a URL
  atrás de JS, pegue uma nova pelo histórico de downloads do navegador se precisar renovar.
- `software`: lista de programas (id do winget) a instalar. Adicionar/remover programas = só editar aqui.

**Ativação do Windows** (`modules\Activation.ps1`) só repete o `slmgr /ato` nativo do Windows,
que puxa sozinho a licença OEM gravada na BIOS/firmware (a edição já vem certa da própria
instalação — não há seleção de chave nem edição aqui). **Nunca adicione um `/skms
<servidor-publico>`** nesse fluxo: isso deixaria de ser "ativação OEM" e viraria contorno de
licenciamento via servidor não autorizado.

## Uso (na máquina do cliente, após instalar o Windows)

Dá dois cliques em **`Iniciar.bat`** — ele já chama o PowerShell com o `-ExecutionPolicy
Bypass` certo, sem precisar decorar comando nenhum. Isso não muda nenhuma configuração
permanente do Windows, vale só pra aquele processo.

Se preferir rodar direto pelo terminal:

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

O script se auto-eleva para administrador e mostra um menu:

```
1) Atualizar drivers (utilitário oficial do fabricante)
2) Instalar programas básicos (Chrome, Acrobat, WinRAR, VLC)
3) Instalar Microsoft 365 Apps (direto da Microsoft)
4) Ativar Windows
5) Dev Kit (Git, VSCode, JDK, Maven, Node, Python, WSL, MobaXterm, VS2026)
0) Executar tudo (Dev Kit fica de fora, é sob demanda)
Q) Sair
```

Logs de cada execução ficam em `logs\setup_<data>.log`.

## Observações importantes

- **Drivers**: só usa o utilitário oficial do fabricante detectado (Dell Command | Update,
  Lenovo System Update, HP Support Assistant). Se a máquina não for de nenhum desses três, o
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
