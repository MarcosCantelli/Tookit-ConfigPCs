# Bootstrap do OpenSSH Server (Windows)

Pré-requisito para usar `remote/remote.ps1` / `remote/remote.sh` numa máquina Windows: ela
precisa ter o **OpenSSH Server** rodando (não vem ativado por padrão numa instalação limpa).
Duas formas de resolver isso, escolha uma:

## 1. Automático, direto na instalação do Windows (recomendado a longo prazo)

Use o `autounattend.xml` desta pasta:

1. Copie `autounattend.xml` pro **raiz** do pendrive/mídia de instalação do Windows.
2. O Windows Setup detecta e aplica sozinho - o resto da instalação continua normal
   (telas de disco, product key, conta de usuário, etc. não mudam).
3. Ele só habilita e inicia o serviço `sshd` + libera a porta 22 no firewall, durante o
   pass "specialize" da instalação.
4. **Teste numa máquina de sobra antes de usar em produção.**

## 2. Manual, numa máquina que já foi instalada sem o autounattend

Rode `tools/Enable-RemoteSsh.ps1` (na raiz do projeto) localmente, uma vez, como
administrador:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Enable-RemoteSsh.ps1
```

Depois disso, a máquina já aceita conexão SSH normalmente e dá pra usar o
`remote/remote.ps1` / `remote/remote.sh` de qualquer PC pra rodar o toolkit nela.
