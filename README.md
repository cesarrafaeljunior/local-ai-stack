# local-ai-stack

Stack reproduzível para executar IA local com **LM Studio/llmster + modelos Qwen + Open WebUI**.

O repositório versiona a **receita do ambiente**, não os pesos dos modelos nem dados pessoais.

## Arquitetura

```text
Browser
  │
  ▼
Open WebUI (Docker)
  │  OpenAI-compatible API
  ▼
LM Studio / llmster (host)
  │
  ▼
Qwen (GPU / RAM)
```

## Escopo inicial

- Linux/Ubuntu.
- LM Studio/`llmster` executado no host.
- Open WebUI executado em Docker.
- Um modelo carregado por vez.
- Perfis `light`, `work` e `heavy`.
- Comando único `ia` para operação diária.

## Por que não colocar os modelos no Git?

Arquivos GGUF podem ter vários gigabytes e variam conforme hardware/quantização. Este repositório guarda apenas os identificadores e parâmetros necessários para baixá-los novamente.

## Perfis

| Perfil | Modelo | Quantização | Uso |
|---|---|---|---|
| `light` | Qwen3 4B | Q4_K_M | tarefas leves |
| `work` | Qwen3 8B | Q4_K_M | uso principal / desenvolvimento |
| `heavy` | Qwen3 14B | Q4_K_M | análise mais pesada com máquina ociosa |

Veja [`docs/MODELS.md`](docs/MODELS.md).

## Instalação em uma máquina nova

Pré-requisitos:

- Docker + Docker Compose v2
- `curl`
- `python3`
- `openssl`
- Driver da GPU adequado, quando houver GPU

Clone:

```bash
git clone <URL_DO_REPOSITORIO>
cd local-ai-stack
```

Bootstrap:

```bash
./scripts/bootstrap.sh
```

Depois:

```bash
ia doctor
ia install work
ia work
ia web
```

Se o modelo já estiver instalado no LM Studio, `ia install work` não baixa novamente.

## Operação diária

```bash
ia light
ia work
ia heavy

ia status
ia models
ia web

ia off
```

`ia off` para o Open WebUI, para a API do LM Studio, descarrega todos os modelos e encerra o `llmster`.

## Open WebUI

URL padrão:

```text
http://localhost:3000
```

A imagem está fixada em `v0.11.1` no `.env.example` para tornar o ambiente reproduzível. Atualize de forma explícita alterando `OPEN_WEBUI_IMAGE` e executando:

```bash
ia update-webui
```

## Dados persistentes

Os dados do Open WebUI ficam em:

```text
data/open-webui/
```

Essa pasta é ignorada pelo Git.

Backup:

```bash
ia backup
```

## Configuração

Modelos:

```text
config/models.json
```

Configuração local:

```text
.env
```

O `.env` nunca deve ser commitado. Use `.env.example` como template.

## Segurança

O Open WebUI só é publicado em `127.0.0.1` por padrão.

Para o container alcançar o LM Studio, o comando `ia` tenta ligar a API apenas à interface `docker0`. Se isso não for possível, ele usa `0.0.0.0` como fallback e exibe um aviso. Nesse caso, revise o firewall e nunca exponha a porta 1234 à internet.

Veja [`docs/SECURITY.md`](docs/SECURITY.md).

## Repositório público ou privado?

Este projeto foi desenhado para poder ser público:

- nenhum GGUF é versionado;
- `.env` é ignorado;
- chats e banco do Open WebUI são ignorados;
- secrets são ignorados;
- apenas configuração e scripts entram no Git.

Ainda assim, para uma primeira configuração pessoal, é prudente criar o repositório como **privado**, validar com `git status` e só então torná-lo público.

## Licença

MIT.
