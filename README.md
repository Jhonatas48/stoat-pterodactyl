# Stoat Development para Pterodactyl

Ambiente **all-in-one apenas para desenvolvimento e homologação** do backend
Stoat. O pacote elimina a necessidade de Docker Compose e `mise` dentro do
servidor Pterodactyl.

Inclui:

- backend Rust do Stoat (compilado a partir do fork configurado);
- MongoDB em Replica Set;
- Redis compatível;
- RabbitMQ;
- MinIO e criação automática do bucket;
- Supervisor para manter todos os processos ativos;
- egg PTDL v2;
- workflow para publicar a imagem no GitHub Container Registry;
- instruções de VS Code Remote SSH.

O LiveKit não está incluído nesta primeira versão. Buttons, select menus,
modals e eventos não dependem dele.

## 1. Publique a imagem

Crie um repositório no GitHub, copie este pacote para ele e envie para a branch
`main`. O workflow `.github/workflows/publish-image.yml` publicará:

```text
ghcr.io/SEU_USUARIO/stoat-pterodactyl-dev:latest
```

No GitHub, abra **Actions**, execute **Build and publish development image** e,
ao terminar, deixe o package público em **Packages > Package settings > Change
visibility > Public**.

Edite `egg-stoat-development.json` e substitua:

```text
ghcr.io/SEU_USUARIO/stoat-pterodactyl-dev:latest
```

pelo endereço real da imagem.

## 2. Importe o egg

1. Abra o painel administrativo do Pterodactyl.
2. Entre em `Nests` e escolha ou crie um nest de desenvolvimento.
3. Use `Import Egg` e selecione `egg-stoat-development.json`.
4. Crie um servidor usando o novo egg.
5. Use, no mínimo, 8 GB de RAM, 4 vCPUs e 30 GB de disco.
6. Crie allocations TCP para `14702`, `14703`, `14704`, `14705` e `14706`.
7. A porta principal recomendada é `14705` (proxy January).

Não exponha MongoDB, Redis, RabbitMQ ou MinIO diretamente à internet.

## 3. Variáveis do servidor

| Variável | Exemplo | Descrição |
|---|---|---|
| `GIT_REPOSITORY` | `https://github.com/jhonatas48/stoatchat.git` | Seu fork |
| `GIT_BRANCH` | `feat/interactions` | Branch em desenvolvimento |
| `PUBLIC_HOST` | `stoat-dev.seudominio.com` | Domínio ou IP público |
| `PUBLIC_SCHEME` | `https` | `http` ou `https` |
| `PUBLIC_WS_SCHEME` | `wss` | `ws` ou `wss` |
| `BUILD_ON_START` | `1` | Recompila quando iniciar |
| `CARGO_BUILD_JOBS` | `2` | Reduza se faltar memória |
| `RUST_LOG` | `info` | Nível dos logs |

As portas internas dos binários Stoat são fixas, conforme o código oficial:

| Serviço | Porta |
|---|---:|
| Delta/API | 14702 |
| Bonfire/WebSocket | 14703 |
| Autumn/arquivos | 14704 |
| January/proxy | 14705 |
| Gifbox | 14706 |

Para HTTPS, coloque o domínio atrás de Nginx, Nginx Proxy Manager, Caddy ou
Cloudflare Tunnel. O proxy precisa encaminhar WebSocket corretamente.

## 4. Primeiro início

O instalador do egg clona o fork em `/home/container/source`. No primeiro
início, o backend é compilado e os serviços são iniciados. A primeira compilação
pode levar vários minutos.

No console, procure por:

```text
[stoat-dev] infraestrutura pronta
[stoat-dev] backend compilado
```

Depois confirme os processos:

```text
delta, bonfire, autumn, january, gifbox, crond
```

O daemon `pushd` fica desabilitado por padrão porque notificações push não são
necessárias para desenvolver interações. Ative com `ENABLE_PUSHD=1`.

## 5. Atualizar e recompilar

Com `BUILD_ON_START=1`, reiniciar o servidor recompila a branch. Para evitar
um `git pull` automático que sobrescreva alterações feitas pelo VS Code,
`PULL_ON_START` vem desativado.

Para buscar alterações remotas manualmente no terminal do VS Code:

```bash
cd source
git pull --ff-only origin "$(git branch --show-current)"
cargo build
```

Depois reinicie o servidor pelo painel.

## 6. VS Code Remote SSH

Leia [VSCODE-REMOTE-SSH.md](VSCODE-REMOTE-SSH.md). O método recomendado conecta
o VS Code à VPS e abre diretamente o volume persistente do servidor.

## Limitações

- O projeto concentra banco, filas e backend em um contêiner.
- É um ambiente de desenvolvimento, não uma arquitetura de produção.
- O frontend web não está incluído.
- O LiveKit/voz não está incluído.
- O egg depende de uma imagem previamente publicada; o JSON sozinho não
  consegue instalar pacotes no contêiner final do Pterodactyl.

