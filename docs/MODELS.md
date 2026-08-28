# Modelos e perfis

## `light` — Qwen3 4B Q4_K_M

Indicado para tarefas simples e baratas: resumos, classificação, pequenas transformações, geração de funções curtas e agentes auxiliares.

Não é o perfil indicado para implementar uma aplicação inteira com autonomia.

## `work` — Qwen3 8B Q4_K_M

Perfil principal.

Indicado para:

- Java/Spring Boot;
- Angular;
- SQL;
- endpoints REST;
- análise de bugs;
- geração de testes;
- documentação;
- refatorações moderadas;
- chat técnico;
- primeiras automações com agentes.

Uma aplicação pode ser construída com ele **feature por feature**, usando ciclos de planejamento, implementação, testes e revisão. Não deve ser tratado como um agente infalível que recebe um único prompt e entrega um sistema inteiro sem validação.

Configuração inicial:

```text
identifier: qwen-work
context: 8192
gpu: max
ttl: 600 s
```

Na máquina de referência (RTX 5060 8 GB), o `estimate-only` do LM Studio para esse perfil retornou aproximadamente 4,68 GiB de memória de GPU com 100% de offload.

## `heavy` — Qwen3 14B Q4_K_M

Indicado para arquitetura, planejamento, revisão e problemas mais complexos.

Com 8 GB de VRAM, parte do modelo/cache pode depender de RAM. Deve ser testado com `--estimate-only` em cada máquina antes de ser adotado.

## Modelos futuros

Modelos Coder maiores, como variantes MoE de ~30B, ficam fora do perfil padrão enquanto a máquina tiver 16 GB de RAM e 8 GB de VRAM.

## Regra operacional

Um modelo carregado por vez.

Vários agentes podem compartilhar o mesmo modelo via API; não é necessário carregar uma cópia por agente.
