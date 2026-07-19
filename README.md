# Toolkit de pós-formatação (Windows)

Automatiza as tarefas que se repetem depois de instalar o Windows numa máquina de cliente:
atualização de drivers pelo utilitário oficial do fabricante, instalação de programas básicos,
instalação do Office (2007/2016 ou 365) e ativação do Windows.

## Estrutura

```
setup.ps1              # entrypoint - rode como administrador
config/config.json      # caminhos do storage, lista de programas, dados do Office 365/HPIA
modules/                 # um arquivo por área (Drivers, Software, Office, Storage, Activation)
tools/Generate-Credential.ps1  # gera a credencial cifrada do storage (rodar 1x)
```

## Configuração inicial (fazer uma vez, na sua máquina)

1. **Gerar a credencial do storage** (usada para buscar o Office 2007/2016):
   ```powershell
   .\tools\Generate-Credential.ps1
   ```
   Isso cria `config\aes.key` e `config\storage_credential.xml`. Esses dois arquivos, juntos,
   permitem decifrar a senha — trate-os como a própria senha. **Recomendado**: crie no
   NAS/servidor uma conta de serviço somente leitura, restrita apenas à pasta de instaladores,
   em vez de usar seu login pessoal/admin.

2. **Editar `config/config.json`**:
   - `storage.sharePath`: caminho UNC do seu servidor/NAS (ex: `\\SEUSERVIDOR\Softwares`).
   - `storage.office2007Zip` / `office2016Zip`: nome dos arquivos zip lá dentro.
   - `office365.odtDownloadUrl`: link atual do Office Deployment Tool
     ([download oficial da Microsoft](https://www.microsoft.com/pt-br/download/details.aspx?id=49117) —
     o link do arquivo muda de vez em quando, pegue o mais recente).
   - `drivers.dell.dcuDownloadUrl` / `drivers.lenovo.suDownloadUrl`: **opcionais** — só são usados
     como fallback se o `winget` estiver indisponível ou a instalação via winget falhar (o caminho
     normal é `winget install Dell.CommandUpdate` / `Lenovo.SystemUpdate`, que já é automático).
   - `drivers.hp.hpiaDownloadUrl`: link atual do HP Image Assistant — este é usado sempre, já que
     não há um id de winget confiável para o HPIA
     (https://ftp.hp.com/pub/caps-softpaq/cmit/HPIA.html — também muda de versão em versão).
   - `software`: lista de programas (id do winget) a instalar. Adicionar/remover programas = só editar aqui.

3. **Ativação do Windows** já vem pronta em `modules\Activation.ps1`: só repete o `slmgr /ato`
   nativo do Windows, que puxa sozinho a licença OEM gravada na BIOS/firmware (a edição já vem
   certa da própria instalação — não há seleção de chave nem edição aqui). **Nunca adicione um
   `/skms <servidor-publico>`** nesse fluxo: isso deixaria de ser "ativação OEM" e viraria
   contorno de licenciamento via servidor não autorizado.

4. Copiar a pasta inteira do projeto (incluindo `config\aes.key` e `config\storage_credential.xml`
   já gerados) para o pendrive/repo privado usado nas máquinas dos clientes.

## Uso (na máquina do cliente, após instalar o Windows)

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

O script se auto-eleva para administrador e mostra um menu:

```
1) Atualizar drivers (utilitário oficial do fabricante)
2) Instalar programas básicos (Chrome, Acrobat, WinRAR, VLC)
3) Instalar Office (2007 / 2016 / 365)
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
- **Office 2007/2016**: pega o zip do seu storage próprio (licença já paga) e instala silenciosamente.
- **Office 365**: baixa direto da CDN oficial da Microsoft; o cliente precisa logar com a conta
  Microsoft 365 depois para ativar.
- **IDs de pacote do winget e switches de CLI dos utilitários de fabricante mudam com o tempo.**
  Se algum passo falhar, o log vai indicar o comando/id que não funcionou — pode ser necessário
  atualizar o id/switch conforme a versão mais recente do fabricante.
- Nunca versionar (`git`) `config/aes.key` nem `config/storage_credential.xml` — já estão no `.gitignore`.
