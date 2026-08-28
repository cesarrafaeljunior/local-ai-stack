# Arquitetura do Local AI Stack

```text
Perfil de inferência
    ↓
Modelo local
    ↓
LM Studio / llmster
    ↓
Open WebUI
    ↓
Preset / Skill / Agent
```

## Responsabilidades

**Perfil de inferência** (`config/models.json`) descreve modelo, quantização, contexto, GPU, prompt, reasoning e parâmetros recomendados.

**Modelo** são os pesos GGUF. Ficam fora do Git e só são instalados com `ia install <perfil>`.

**LM Studio/llmster** executa o modelo e expõe a API.

**Open WebUI** é a interface e camada de presets. Um preset pode combinar modelo base + system prompt + parâmetros + knowledge + tools + Skills.

**Skills** descrevem procedimentos reutilizáveis. **Agents** executam loops usando modelo, Skills e ferramentas.

## Perfis v1

| Perfil | Modelo | Papel |
|---|---|---|
| `light` | Qwen3 4B Instruct 2507 | tarefas leves |
| `work` | Qwen3 8B | uso geral principal |
| `code` | Qwen2.5-Coder 7B | desenvolvimento |
| `heavy` | Qwen3 14B | análise geral pesada |
| `code-heavy` | Qwen2.5-Coder 14B | desenvolvimento pesado |

Só `work` precisa estar instalado na v1.

## Reasoning

Qwen3 8B/14B suporta thinking e non-thinking. O usuário pode usar `/think` ou `/no_think`; o comando mais recente prevalece.

`work` mantém reasoning disponível e pede profundidade proporcional à tarefa.

`heavy` favorece thinking e inclui `/think` no system prompt.

`light` usa Qwen3 4B Instruct 2507, variante non-thinking, de propósito.

Qwen2.5-Coder não usa esses soft switches; `code` e `code-heavy` controlam profundidade pelo system prompt.

## Portabilidade

Git contém configuração, prompts, scripts, presets exportados, Skills e docs.

Git não contém GGUF, `.env`, API keys, chats, banco do Open WebUI, uploads ou backups.
