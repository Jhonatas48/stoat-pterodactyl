# Integrar o VS Code ao servidor Pterodactyl

O servidor Pterodactyl não executa SSH dentro do contêiner. O VS Code deve se
conectar por SSH à **VPS/nó onde o Wings está instalado** e abrir o volume do
servidor Stoat.

## 1. Instale a extensão

No seu Windows, instale no VS Code:

- `Remote - SSH`, da Microsoft;
- `rust-analyzer`, após abrir a janela remota;
- opcionalmente `Even Better TOML`.

## 2. Crie um usuário na VPS

Na VPS:

```bash
sudo adduser stoatdev
sudo apt update
sudo apt install -y acl
```

Não adicione esse usuário ao grupo `docker`. Ele precisa editar somente o
volume do servidor, não controlar todos os contêineres da VPS.

## 3. Descubra o UUID do servidor

No painel administrativo do Pterodactyl, abra o servidor e copie o UUID. No nó,
os volumes normalmente ficam em:

```text
/var/lib/pterodactyl/volumes/UUID_DO_SERVIDOR
```

Confirme sem alterar nada:

```bash
sudo ls -la /var/lib/pterodactyl/volumes/UUID_DO_SERVIDOR
```

## 4. Conceda acesso somente ao volume Stoat

Substitua o UUID e execute:

```bash
sudo setfacl -R -m u:stoatdev:rwx /var/lib/pterodactyl/volumes/UUID_DO_SERVIDOR
sudo setfacl -R -d -m u:stoatdev:rwx /var/lib/pterodactyl/volumes/UUID_DO_SERVIDOR
sudo setfacl -m u:stoatdev:--x /var/lib/pterodactyl
sudo setfacl -m u:stoatdev:--x /var/lib/pterodactyl/volumes
```

Crie um atalho no diretório do usuário:

```bash
sudo ln -s /var/lib/pterodactyl/volumes/UUID_DO_SERVIDOR /home/stoatdev/stoat-server
sudo chown -h stoatdev:stoatdev /home/stoatdev/stoat-server
```

Essas ACLs não concedem acesso a outros servidores do Pterodactyl.

## 5. Configure uma chave SSH no Windows

No PowerShell:

```powershell
ssh-keygen -t ed25519 -C "vscode-stoat"
type $env:USERPROFILE\.ssh\id_ed25519.pub
```

Copie a chave pública mostrada. Na VPS, autenticado com seu usuário
administrativo:

```bash
sudo -u stoatdev mkdir -p /home/stoatdev/.ssh
sudo -u stoatdev chmod 700 /home/stoatdev/.ssh
sudo -u stoatdev nano /home/stoatdev/.ssh/authorized_keys
sudo -u stoatdev chmod 600 /home/stoatdev/.ssh/authorized_keys
```

Cole apenas a chave pública. Nunca copie a chave privada para a VPS.

## 6. Configure o SSH do Windows

Edite `%USERPROFILE%\.ssh\config`:

```sshconfig
Host stoat-dev
    HostName IP_DA_VPS
    User stoatdev
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 30
    ServerAliveCountMax 3
```

Teste no PowerShell:

```powershell
ssh stoat-dev
```

## 7. Abra o projeto

No VS Code:

1. pressione `Ctrl+Shift+P`;
2. execute `Remote-SSH: Connect to Host`;
3. selecione `stoat-dev`;
4. escolha `File > Open Folder`;
5. abra `/home/stoatdev/stoat-server/source`.

Quando solicitado, confie somente porque essa é sua própria VPS e seu próprio
fork.

## 8. rust-analyzer e Cargo

O Rust está dentro do contêiner, não diretamente na VPS. Por isso, o
`rust-analyzer` do Remote SSH não encontrará o toolchain automaticamente.

Há duas opções:

### Opção simples: edição remota e compilação pelo painel

Edite pelo VS Code e reinicie o servidor no Pterodactyl com
`BUILD_ON_START=1`. É a opção mais segura e exige menos configuração.

### Opção avançada: Dev Containers

Exigiria acesso do usuário ao Docker da VPS, o que permitiria controlar outros
contêineres. Não é recomendado em um nó que hospeda outros servidores.

Para este egg, use o VS Code para edição, busca, Git e comparação; deixe Cargo
e os binários executarem dentro do Pterodactyl.

## 9. Usar Git pelo VS Code

O Git pode reclamar de propriedade diferente. Configure somente esse projeto:

```bash
git config --global --add safe.directory /home/stoatdev/stoat-server/source
```

Para enviar commits, configure sua identidade:

```bash
git config --global user.name "SEU NOME"
git config --global user.email "SEU EMAIL"
```

Use uma chave SSH separada ou um token de acesso do GitHub. Não salve tokens em
arquivos do repositório ou variáveis públicas do egg.

## 10. Segurança

- Não abra a porta `22` para o mundo inteiro se puder limitá-la ao seu IP.
- Desative autenticação SSH por senha depois de validar a chave.
- Não use `chmod -R 777` no volume.
- Não dê ao usuário `stoatdev` acesso a `/var/run/docker.sock`.
- Faça commits frequentes antes de atualizar ou reinstalar o servidor.

