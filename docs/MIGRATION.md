# Migração para outra máquina

## O que vem pelo Git

- Docker Compose;
- scripts;
- lista de modelos;
- parâmetros dos perfis;
- documentação;
- Skills/prompts futuramente.

## O que não vem pelo Git

- modelos GGUF;
- `.env`;
- `WEBUI_SECRET_KEY`;
- chats;
- banco do Open WebUI;
- uploads;
- caches.

## Nova máquina

```bash
git clone <URL>
cd local-ai-stack
./scripts/bootstrap.sh

ia doctor
ia install work
ia work
```

## Migrar chats/configurações do Open WebUI

Faça backup da pasta:

```text
data/open-webui/
```

e restaure essa pasta na nova máquina **junto com a mesma `WEBUI_SECRET_KEY`**.

Se a chave mudar, sessões existentes serão invalidadas e integrações que dependam dela podem precisar ser reconectadas.

## Migrar da instalação Docker anterior

Se já existe um container chamado `open-webui`:

```bash
./scripts/migrate-openwebui-data.sh open-webui
docker stop open-webui
```

Depois:

```bash
ia work
```

O script de migração copia os dados, mas não remove o container antigo.
