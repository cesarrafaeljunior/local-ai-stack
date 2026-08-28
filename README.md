# local-ai-stack

Stack reproduzível para IA local com **LM Studio/llmster + modelos locais + Open WebUI**.

## Perfis

| Comando | Modelo | Objetivo |
|---|---|---|
| `ia light` | Qwen3 4B Instruct 2507 | tarefas leves |
| `ia work` | Qwen3 8B | uso geral |
| `ia code` | Qwen2.5-Coder 7B | desenvolvimento |
| `ia heavy` | Qwen3 14B | análise pesada |
| `ia code-heavy` | Qwen2.5-Coder 14B | desenvolvimento pesado |

Perfis configurados não são baixados automaticamente.

```bash
ia models
ia install code
ia code
```

## Comandos

```bash
ia <perfil>
ia install <perfil>
ia estimate <perfil>
ia info <perfil>
ia prompt <perfil>

ia models
ia status
ia doctor
ia web
ia off

ia backup
ia update-webui

ia webui-export
ia webui-import
ia webui-sync
```

Os nomes dos perfis são dinâmicos: adicionar um perfil em `config/models.json` não exige editar `scripts/ia`.

## Reasoning

Qwen3 suporta `/think` e `/no_think`. O `work` usa profundidade proporcional à tarefa; `heavy` favorece thinking profundo.

Qwen2.5-Coder não usa esses soft switches.

## Prompts

Os system prompts ficam em `prompts/` e são associados aos perfis em `config/models.json`.

```bash
ia prompt work
ia info work
```

Use-os em Model presets do Open WebUI e depois versione os presets com `ia webui-export`.

Veja `docs/ARCHITECTURE.md` e `docs/OPEN_WEBUI.md`.

## Desligamento total

```bash
ia off
```

## Dados fora do Git

Não versione `.env`, API keys, GGUF, chats, banco do Open WebUI, uploads ou backups.

## Licença

MIT.
