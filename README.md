# Local AI Stack

Ambiente local de IA para uso geral, programação e execução de agentes de código, com modelos rodando localmente via **LM Studio / llmster**, interface de chat via **Open WebUI** e automação agentic via **OpenCode**.

O objetivo deste repositório é ser a **fonte de verdade da infraestrutura local de IA**: perfis de modelos, prompts, configuração do Open WebUI, configuração do OpenCode, scripts de automação, políticas de segurança e documentação.

> Modelos, bancos locais, históricos, credenciais, uploads e outros dados privados não devem ser versionados.

---

## Status atual

Ambiente validado com:

- Ubuntu 24.04 LTS
- Intel Core i5-12600KF
- 16 GiB RAM
- NVIDIA GeForce RTX 5060
- ~8 GiB VRAM
- LM Studio / llmster
- Open WebUI
- OpenCode 1.18.25
- Qwen3 8B
- Qwen2.5-Coder 7B

Perfis principais:

| Uso | Comando | Cliente | Modelo | Contexto |
|---|---|---|---|---:|
| Trabalho geral | `ia work` | Open WebUI | Qwen3 8B | 8192 |
| Chat de código | `ia code` | Open WebUI | Qwen2.5-Coder 7B | 16384 |
| Coding Agent | `ia agent` | OpenCode | Qwen3 8B | 8192 atualmente |

O perfil `code` foi validado com contexto de **16K**, GPU offload de 100% e pico real de aproximadamente **6159 MiB** em uma RTX 5060 de 8151 MiB.

---

# 1. Conceitos principais

É importante separar três coisas:

```text
MODELO
  ↓
gera tokens / "cérebro"

CLIENTE
  ↓
interface usada para conversar com o modelo

AGENTE / HARNESS
  ↓
dá ferramentas ao modelo para agir sobre arquivos, terminal, Git, testes etc.
```

Neste stack:

```text
LM Studio
├── Qwen3 8B
└── Qwen2.5-Coder 7B

Open WebUI
├── Local Work
└── Local Code

OpenCode
└── Coding Agent
```

---

# 2. Arquitetura

## 2.1 Chat geral

```text
Usuário
  ↓
Open WebUI
  ↓
Local Work
  ↓
LM Studio
  ↓
Qwen3 8B
```

Uso esperado:

- perguntas gerais;
- planejamento;
- arquitetura;
- brainstorming;
- estudo;
- explicações técnicas.

---

## 2.2 Chat especializado em código

```text
Usuário
  ↓
Open WebUI
  ↓
Local Code
  ↓
LM Studio
  ↓
Qwen2.5-Coder 7B
```

Uso esperado:

- geração de código;
- debugging;
- refatoração;
- revisão;
- explicação técnica;
- testes;
- análise de trechos de implementação.

---

## 2.3 Coding Agent

```text
Usuário
  ↓
OpenCode
  ↓
Qwen3 8B
  ↓
tool calls
  ├── read
  ├── glob
  ├── grep
  ├── edit
  ├── bash
  └── subagentes permitidos
  ↓
repositório atual
```

O OpenCode fornece as “mãos” ao modelo.

O modelo sozinho não consegue:

- abrir arquivos;
- modificar código;
- executar Maven/npm;
- rodar testes;
- analisar `git diff`;
- repetir um ciclo de correção automaticamente.

---

# 3. Por que o agente usa Qwen3 8B?

O Qwen2.5-Coder 7B foi validado como bom modelo de programação em chat, porém **não produziu tool calls estruturados corretamente** no stack atual.

Exemplo observado:

```json
{
  "content": "{ \"name\": \"get_project_name\", \"arguments\": {} }",
  "tool_calls": [],
  "finish_reason": "stop"
}
```

Ou seja: ele entendeu a intenção, mas escreveu a chamada como texto comum.

O Qwen3 8B produziu corretamente:

```json
{
  "tool_calls": [
    {
      "type": "function",
      "function": {
        "name": "get_project_name",
        "arguments": "{}"
      }
    }
  ],
  "finish_reason": "tool_calls"
}
```

E foi validado no OpenCode usando ferramentas reais como:

```text
Glob
Read
Explore
```

Por isso a divisão atual é:

```text
Qwen2.5-Coder 7B
→ especialista em programação no chat

Qwen3 8B
→ modelo geral + controlador agentic
```

Essa decisão pode mudar futuramente se outro modelo especializado em agentic coding for validado.

---

# 4. Política de memória

Embora o LM Studio consiga manter múltiplos modelos carregados, este stack usa atualmente:

```text
1 modelo carregado por vez
```

Motivo:

```text
RTX 5060
~8 GiB VRAM
16 GiB RAM
```

Manter Qwen3 8B e Qwen2.5-Coder 7B simultaneamente pressionaria VRAM/RAM e poderia forçar offload para CPU.

A troca automática de modelo é preferida no hardware atual.

---

# 5. Estrutura do repositório

Estrutura esperada:

```text
local-ai-stack/
├── README.md
├── docker-compose.yml
├── .env.example
├── config/
│   ├── models.json
│   └── opencode/
│       └── opencode.json
├── prompts/
│   ├── work.md
│   ├── code.md
│   ├── light.md
│   ├── heavy.md
│   └── code-heavy.md
├── scripts/
│   ├── ia
│   ├── opencode-agent.sh
│   └── webui-models.sh
├── data/
│   └── open-webui/
└── backups/
```

## Deve ser versionado

```text
README.md
docker-compose.yml
.env.example
config/
prompts/
scripts/
```

## Não deve ser versionado

```text
.env
data/
backups/
*.gguf
*.safetensors
webui.db
webui.db-wal
webui.db-shm
tokens
senhas
API keys
cookies
históricos
uploads
credenciais
```

---

# 6. Pré-requisitos

Ferramentas principais:

```text
Ubuntu/Linux
Docker
Docker Compose
LM Studio / llmster
NVIDIA Driver
Node.js
npm
Python 3
Git
curl
iproute2
OpenCode
```

Validação:

```bash
docker --version
docker compose version
node --version
npm --version
python3 --version
git --version
nvidia-smi
lms --version
opencode --version
```

---

# 7. Instalação rápida

## 7.1 Clonar

```bash
git clone <URL_DO_REPOSITORIO>
cd local-ai-stack
```

---

## 7.2 Configurar ambiente

Se existir `.env.example`:

```bash
cp .env.example .env
```

Edite apenas valores locais necessários.

```bash
nano .env
```

Nunca faça commit do `.env`.

---

## 7.3 OpenCode

Instalação validada:

```bash
npm install -g opencode-ai
```

Verifique:

```bash
opencode --version
```

Versão validada durante a configuração:

```text
1.18.25
```

---

## 7.4 Instalar modelos

Exemplos:

```bash
ia install work
```

```bash
ia install code
```

---

## 7.5 Carregar perfil geral

```bash
ia work
```

---

## 7.6 Carregar perfil de código

```bash
ia code
```

---

## 7.7 Abrir Open WebUI

```bash
ia web
```

URL padrão:

```text
http://localhost:3000
```

---

## 7.8 Verificar o ambiente

```bash
ia status
```

```bash
ia doctor
```

---

# 8. Perfis

A fonte de verdade é:

```text
config/models.json
```

## `work`

Modelo:

```text
Qwen3 8B
```

Finalidades:

- chat geral;
- planejamento;
- explicações;
- base física atual do coding agent.

Contexto atual:

```text
8192
```

O aumento para 16K ainda deve ser testado especificamente para uso agentic antes de ser adotado como padrão.

---

## `code`

Modelo:

```text
Qwen2.5-Coder 7B
```

Finalidades:

- chat técnico;
- geração de código;
- debugging;
- refatoração;
- revisão.

Contexto:

```text
16384
```

Configuração validada em hardware real.

---

## `light`

Perfil leve.

Pode ser declarado no `models.json` sem estar instalado.

---

## `heavy`

Perfil geral mais pesado.

Deve ser validado antes de uso padrão.

---

## `code-heavy`

Perfil de código mais pesado.

Também deve ser validado individualmente por consumo de VRAM/RAM.

---

# 9. Open WebUI

## 9.1 URL

```text
http://localhost:3000
```

O bind do container deve permanecer local sempre que possível:

```text
127.0.0.1:3000 → container:8080
```

---

## 9.2 Credenciais do Open WebUI

Na primeira inicialização, crie uma conta local pela própria interface.

As credenciais são armazenadas localmente no banco do Open WebUI.

Não existe credencial padrão que deva ser colocada no Git.

Nunca versionar:

```text
usuário
senha
hash de senha
sessões
cookies
webui.db
```

---

## 9.3 Persistência

Diretório:

```text
data/open-webui/
```

Banco principal:

```text
data/open-webui/webui.db
```

Esse diretório é privado.

---

## 9.4 Local Work

Base:

```text
Qwen3 8B
```

Uso:

- trabalho geral;
- planejamento;
- brainstorming;
- estudo;
- explicações.

---

## 9.5 Local Code

Base:

```text
Qwen2.5-Coder 7B
```

Parâmetros validados:

```text
max_tokens       4096
temperature      0.7
top_p            0.8
top_k            20
repeat_penalty   1.1
reasoning_effort ausente
```

Capacidades extras foram desativadas durante os testes para reduzir consumo desnecessário da janela de contexto.

---

# 10. Context window

A janela de contexto contém tudo:

```text
system prompt
+ histórico
+ mensagem atual
+ ferramentas
+ arquivos
+ RAG
+ resposta
```

Exemplo real de truncamento observado:

```text
prompt_tokens:      7690
completion_tokens:   502
total_tokens:       8192
```

A resposta foi cortada porque:

```text
7690 + 502 = 8192
```

Por isso:

```text
max_tokens = 4096
```

não significa que o modelo sempre terá 4096 tokens disponíveis para responder.

A resposta máxima real depende de:

```text
context_length - tokens já utilizados
```

---

# 11. LM Studio / llmster

## Listar modelos

```bash
lms ls
```

## Modelos carregados

```bash
lms ps
```

## Ver servidor

```bash
ss -ltnp | grep ':1234'
```

No ambiente validado:

```text
172.17.0.1:1234
```

Esse IP pertence à bridge do Docker e **não deve ser hardcoded em configuração pública**.

---

## API

Listar modelos:

```bash
curl -sS \
  http://172.17.0.1:1234/v1/models \
  | python3 -m json.tool
```

O launcher do agent deve descobrir `docker0` automaticamente.

---

## Estimar memória

Exemplo:

```bash
lms load --estimate-only qwen/qwen2.5-coder-7b \
  --gpu max \
  --context-length 16384
```

Resultado observado:

```text
Context Length: 16,384
GPU Offload: 100%
Estimated GPU Memory: 4.36 GiB
Confidence: LOW
```

O benchmark real é mais importante que a estimativa.

---

## Medir VRAM

```bash
nvidia-smi
```

Resumo:

```bash
nvidia-smi \
  --query-gpu=name,memory.used,memory.total,utilization.gpu \
  --format=csv,noheader
```

Monitoramento:

```bash
watch -n 1 nvidia-smi
```

---

# 12. OpenCode

O OpenCode é o harness/coding agent.

Ele conecta um modelo a ferramentas reais.

Exemplo:

```text
Usuário:
"Corrija a validação do cadastro."

OpenCode/Qwen:
  ↓
glob
  ↓
read
  ↓
grep
  ↓
edit
  ↓
mvn test
  ↓
analisa falha
  ↓
edit
  ↓
mvn test
  ↓
git diff
```

---

# 13. Configuração do OpenCode

Arquivo central:

```text
config/opencode/opencode.json
```

Provider:

```text
lmstudio
```

Base URL:

```text
{env:OPENCODE_LMSTUDIO_BASE_URL}
```

Variáveis de ambiente usadas pelo launcher:

```text
OPENCODE_LMSTUDIO_BASE_URL
OPENCODE_CONFIG
OPENCODE_CONFIG_DIR
```

No uso normal, o script `ia agent` deve definir tudo automaticamente.

---

## Modelos registrados

Agent padrão:

```text
lmstudio/qwen-work
```

Modelo de código registrado:

```text
lmstudio/qwen-code
```

O fato de `qwen-code` estar registrado não significa que ele seja usado pelo agente padrão.

---

# 14. Permissões do agente

Configuração inicial conservadora.

## Permitido sem confirmação

```text
read
glob
grep
list
explore
git status
git diff
git log
```

## Solicita confirmação

```text
edit
bash genérico
build
testes
instalações
comandos de aplicação
```

## Negado

```text
git commit
git push
webfetch
websearch
subagentes não permitidos
```

A política pode ser relaxada gradualmente conforme o agente for validado.

---

# 15. TUI do OpenCode

Para uso diário, prefira:

```bash
ia agent
```

Isso abre a interface interativa do OpenCode no terminal.

Na TUI é possível:

- acompanhar tool calls;
- visualizar decisões;
- aprovar ações;
- rejeitar ações;
- revisar alterações;
- trocar modelo;
- trocar agente;
- gerenciar sessões.

---

## `opencode run`

Modo não interativo.

Exemplo:

```bash
ia agent run plan \
  "Analise o projeto atual."
```

Cuidado:

Permissões configuradas como `ask` podem ser rejeitadas automaticamente nesse modo, pois não existe interface para aprovar.

Para desenvolvimento supervisionado, use a TUI.

---

# 16. Comando `ia`

Comandos principais esperados:

```text
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
ia update-webui
ia backup
ia webui-export
ia webui-import
ia webui-sync
ia agent
ia agent plan
ia agent build
ia agent run <plan|build> "tarefa"
ia agent doctor
```

---

## `ia work`

```bash
ia work
```

Carrega o perfil geral.

---

## `ia code`

```bash
ia code
```

Carrega o perfil especializado em código.

---

## `ia agent`

```bash
ia agent
```

Deve:

```text
1. descobrir docker0;
2. configurar OpenCode;
3. verificar o modelo agentic;
4. carregar automaticamente o modelo necessário;
5. validar a API do LM Studio;
6. abrir a TUI;
7. manter o diretório atual como workspace.
```

---

## `ia agent plan`

```bash
ia agent plan
```

Para:

- análise;
- compreensão da codebase;
- planejamento;
- investigação;
- preparação antes de editar.

---

## `ia agent build`

```bash
ia agent build
```

Para:

- implementação;
- edição;
- execução de build/testes;
- correções.

---

## `ia agent doctor`

```bash
ia agent doctor
```

Diagnóstico da integração:

```text
OpenCode
modelo agentic
perfil físico
config
config dir
LM Studio base URL
modelo carregado
API
projeto atual
```

---

# 17. Como o agente sabe qual projeto usar?

O OpenCode usa o diretório atual.

Exemplo:

```bash
cd ~/Documentos/projetos/orbiafly
ia agent
```

O workspace será:

```text
/home/cesar/Documentos/projetos/orbiafly
```

Outro projeto:

```bash
cd ~/Documentos/projetos/CrFlix
ia agent
```

Agora o workspace é `CrFlix`.

A infraestrutura é global; o contexto é local ao projeto.

---

# 18. AGENTS.md específico por projeto

Cada aplicação pode ter:

```text
AGENTS.md
```

Exemplo:

```text
orbiafly/
├── AGENTS.md
├── pom.xml
├── src/
└── ...
```

Exemplo de conteúdo:

```markdown
# Projeto

Java 21 + Spring Boot.

## Arquitetura

Controller → Service → Repository.

## Banco

PostgreSQL.

Mudanças de schema devem usar migration.

## Build

./mvnw clean verify

## Regras

- preserve padrões existentes;
- procure implementações semelhantes antes de criar abstrações;
- execute testes relevantes;
- não faça commit automaticamente;
- não faça push automaticamente.
```

Separação:

```text
local-ai-stack
→ regras reutilizáveis

projeto/AGENTS.md
→ conhecimento específico do projeto
```

---

# 19. Credenciais

## LM Studio

No setup local atual, a API não depende de chave OpenAI/Anthropic.

Base local:

```text
http://<docker0>:1234/v1
```

Não existe API key externa obrigatória para os modelos locais.

---

## OpenCode

Usando somente:

```text
provider = lmstudio
```

também não exige API key externa.

O OpenCode fala diretamente com o LM Studio.

---

## Open WebUI

A conta é criada localmente pela interface.

Não documente senha real.

Não coloque credenciais no `.env.example`.

---

## GitHub

O stack local não precisa de GitHub token para funcionar.

Se futuramente houver automação com issues/PRs:

- use variável de ambiente;
- prefira secret manager;
- use permissões mínimas;
- nunca versionar PAT/token.

---

# 20. Publicação segura no GitHub

Antes de tornar público:

```bash
git status
```

```bash
git ls-files
```

Verifique `.env`:

```bash
git check-ignore -v .env
```

Verifique banco:

```bash
git check-ignore -v data/open-webui/webui.db
```

Procure nomes suspeitos:

```bash
git ls-files | grep -Ei \
'env|secret|token|password|passwd|credential|key|webui\.db|backup|gguf|safetensors'
```

Procure conteúdo sensível:

```bash
git grep -nEi \
'(api[_-]?key|password|passwd|secret|token)[[:space:]]*[:=][[:space:]]*[^[:space:]]+'
```

---

# 21. Backup

Backup do Open WebUI:

```bash
ia backup
```

Diretório:

```text
backups/
```

Nunca versionar backups.

---

# 22. Troubleshooting

## Open WebUI corta resposta

Verifique:

```text
prompt_tokens
completion_tokens
total_tokens
context_length
```

Se `total_tokens == context_length`, a geração atingiu o teto.

Possíveis ações:

- abrir novo chat;
- reduzir histórico;
- reduzir capacidades;
- remover ferramentas desnecessárias;
- aumentar contexto após benchmark.

---

## `reasoning_effort` inválido

Erro observado:

```text
Invalid 'reasoning_effort' value: 'hard'
```

Foi causado por configuração persistida por usuário no Open WebUI.

Modelos que não suportam esse parâmetro não devem recebê-lo.

---

## OpenCode não chama ferramentas

Teste direto via LM Studio.

Resultado correto:

```text
finish_reason = tool_calls
tool_calls != []
```

Resultado incorreto:

```text
finish_reason = stop
tool_calls = []
```

com chamada escrita apenas no `content`.

---

## `ProviderModelNotFoundError`

Exemplo:

```text
Model not found: lmstudio/qwen-work
```

Verifique se o OpenCode carregou:

```text
OPENCODE_CONFIG
OPENCODE_CONFIG_DIR
OPENCODE_LMSTUDIO_BASE_URL
```

Uso recomendado:

```bash
ia agent
```

em vez de exports manuais.

---

## `auto-rejecting`

Acontece principalmente em:

```bash
opencode run
```

quando uma ação exige `ask`.

Use a TUI:

```bash
ia agent
```

---

## LM Studio não responde em `127.0.0.1:1234`

Verifique:

```bash
ss -ltnp | grep ':1234'
```

O stack atual pode usar:

```text
172.17.0.1:1234
```

pela bridge Docker.

---

# 23. Fluxo de desenvolvimento agentic

Objetivo inicial supervisionado:

```text
TASK
  ↓
PLAN
  ↓
BUILD
  ↓
BUILD/COMPILAÇÃO
  ↓
TESTES
  ↓
BUG HUNT
  ↓
REVIEW
  ↓
problema?
 ↙       ↘
sim       não
 ↓         ↓
corrige   finaliza
 ↓
testa novamente
```

Primeiro validar manualmente.

Depois automatizar partes seguras.

---

# 24. Agentes futuros

Estrutura futura possível:

```text
agents/
├── coder/
├── reviewer/
├── tester/
└── bug-hunter/
```

Possíveis responsabilidades:

```text
coder
→ implementação

tester
→ testes e cenários de falha

reviewer
→ revisão sem edição

bug-hunter
→ procura regressões e problemas
```

O mesmo modelo físico pode atender vários agentes se as instruções e permissões forem diferentes.

---

# 25. Skills futuras

Estrutura prevista:

```text
skills/
```

Skills devem conter conhecimento ou procedimentos reutilizáveis.

Exemplos:

```text
spring-boot-review
angular-feature
database-migration
github-issue-workflow
security-review
```

O objetivo é manter skills reutilizáveis no `local-ai-stack` e regras específicas no próprio projeto.

---

# 26. Decisões arquiteturais

## Um modelo físico pode ter múltiplas finalidades

```text
Qwen3 8B
├── Local Work
├── futuro Local Study
└── Coding Agent
```

---

## Nomes para o usuário

```text
ia work
→ trabalho geral

ia code
→ chat de programação

ia agent
→ coding agent
```

O usuário não deve precisar saber qual perfil físico o agent carrega internamente.

---

## Modelo não é agente

```text
Qwen
→ raciocínio/geração

OpenCode
→ ferramentas/loop
```

---

## Infraestrutura e projeto são separados

```text
local-ai-stack
→ infraestrutura local reutilizável

orbiafly
→ regras e contexto do Orbiafly

CrFlix
→ regras e contexto do CrFlix
```

---

# 27. Roadmap

## Validado

- [x] LM Studio local
- [x] GPU NVIDIA
- [x] Open WebUI
- [x] perfil `work`
- [x] perfil `code`
- [x] `code` com 16K
- [x] OpenCode instalado
- [x] provider LM Studio
- [x] tool calling com Qwen3 8B
- [x] leitura de arquivos pelo OpenCode
- [x] política inicial de permissões
- [x] integração conceitual `ia agent`

## Próximos passos

- [ ] validar `ia agent` em projeto real;
- [ ] criar `AGENTS.md` do Orbiafly;
- [ ] executar primeira task supervisionada;
- [ ] validar implementação → teste → correção;
- [ ] criar `coder`;
- [ ] criar `tester`;
- [ ] criar `reviewer`;
- [ ] criar `bug-hunter`;
- [ ] avaliar `work` em 16K;
- [ ] criar `Local Study`;
- [ ] testar `light`;
- [ ] testar `heavy`;
- [ ] testar `code-heavy`;
- [ ] avaliar modelo especializado em agentic coding;
- [ ] integrar issues GitHub;
- [ ] criar automações por horário;
- [ ] criar skills reutilizáveis.

---

# 28. Quick Reference

## Trabalho geral

```bash
ia work
ia web
```

## Chat de código

```bash
ia code
ia web
```

## Coding Agent

```bash
cd /caminho/do/projeto
ia agent
```

## Planejamento

```bash
ia agent plan
```

## Implementação

```bash
ia agent build
```

## Diagnóstico

```bash
ia status
ia doctor
ia agent doctor
```

## Modelos

```bash
ia models
lms ls
lms ps
```

## Desligar

```bash
ia off
```

---

# 29. Regra de ouro

Este repositório deve conter a **receita**, não os dados privados.

```text
Git
→ configuração
→ scripts
→ prompts
→ documentação
→ regras

Máquina local
→ modelos
→ banco do Open WebUI
→ chats
→ uploads
→ backups
→ credenciais
```

Assim qualquer máquina compatível pode reproduzir o ambiente sem expor dados pessoais ou segredos.
