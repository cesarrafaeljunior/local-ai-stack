# Open WebUI — Presets versionados

## Configurar `work`

Com `ia work` ativo:

1. Abra `Workspace > Models`.
2. Crie um Model.
3. Nome: `Local Work`.
4. ID: `local-work`.
5. Base Model: `qwen-work`.
6. Copie `ia prompt work` para o System Prompt.
7. Use `ia info work` como referência dos parâmetros.
8. Para Qwen3 thinking: `temperature=0.6`, `top_p=0.95`, `top_k=20`, `min_p=0`.
9. Ative a detecção de reasoning tags `<think>...</think>`.

O usuário continua podendo usar `/think` e `/no_think`.

## Presets planejados

| Preset | Base | Prompt |
|---|---|---|
| Local Light | `qwen-light` | `prompts/light.md` |
| Local Work | `qwen-work` | `prompts/work.md` |
| Local Code | `qwen-code` | `prompts/code.md` |
| Local Heavy | `qwen-heavy` | `prompts/heavy.md` |
| Local Code Heavy | `qwen-code-heavy` | `prompts/code-heavy.md` |

Crie cada preset somente depois que o modelo correspondente puder ser carregado.

## Versionar presets

Crie uma API key de administrador do Open WebUI e adicione somente ao `.env`:

```env
OPEN_WEBUI_API_KEY=...
```

Nunca commite a chave.

Exportar:

```bash
ia webui-export
```

Arquivo versionado:

```text
config/open-webui/models.json
```

Restaurar sem apagar outros presets:

```bash
ia webui-import
```

Reconciliar exatamente com o Git:

```bash
ia webui-sync
```

O `sync` se recusa a rodar se o arquivo estiver vazio.
