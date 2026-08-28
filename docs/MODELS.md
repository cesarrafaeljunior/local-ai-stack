# Modelos e perfis

## `light` — Qwen3 4B Instruct 2507 Q4_K_M

Perfil rápido e econômico. A variante escolhida é non-thinking.

## `work` — Qwen3 8B Q4_K_M

Perfil padrão para chat, desenvolvimento, debugging, planejamento e análise.

Reasoning: thinking disponível por padrão, com `/think` e `/no_think`.

## `code` — Qwen2.5-Coder 7B Q4_K_M

Especialista em geração/correção de código, testes, debugging, refatoração e code agents.

## `heavy` — Qwen3 14B Q4_K_M

Análise geral pesada. Deve ser validado com `ia estimate heavy` antes de uso regular.

## `code-heavy` — Qwen2.5-Coder 14B Q4_K_M

Código pesado com a máquina ociosa. Também exige `estimate-only` e benchmark.

## Política operacional

Um modelo carregado por vez. Vários agentes podem compartilhar uma instância via API.
