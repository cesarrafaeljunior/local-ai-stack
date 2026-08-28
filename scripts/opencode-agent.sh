#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

OPENCODE_CONFIG_FILE="$ROOT/config/opencode/opencode.json"
OPENCODE_CONFIG_DIRECTORY="$ROOT/config/opencode"

# Perfil físico utilizado pelo coding agent.
#
# Embora o perfil se chame "work" no stack, ele contém o Qwen3 8B,
# que foi o modelo validado para tool calling.
AGENT_PROFILE="work"
AGENT_MODEL="lmstudio/qwen-work"
AGENT_MODEL_IDENTIFIER="qwen-work"

fail() {
  printf 'ERRO: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '==> %s\n' "$*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 \
    || fail "Comando obrigatório não encontrado: $1"
}

docker_bridge_ip() {
  ip -4 addr show docker0 2>/dev/null \
    | awk '/inet / {print $2; exit}' \
    | cut -d/ -f1
}

setup_environment() {
  local bridge_ip

  bridge_ip="$(docker_bridge_ip)"

  [[ -n "$bridge_ip" ]] \
    || fail "Não foi possível descobrir o IPv4 da interface docker0."

  export OPENCODE_LMSTUDIO_BASE_URL="http://${bridge_ip}:1234/v1"
  export OPENCODE_CONFIG="$OPENCODE_CONFIG_FILE"
  export OPENCODE_CONFIG_DIR="$OPENCODE_CONFIG_DIRECTORY"
}

agent_model_loaded() {
  lms ps 2>/dev/null | grep -Fq "$AGENT_MODEL_IDENTIFIER"
}

ensure_agent_model() {
  if agent_model_loaded; then
    info "Modelo agentic já está carregado: $AGENT_MODEL_IDENTIFIER"
    return
  fi

  info "Modelo agentic não está carregado."
  info "Ativando automaticamente o perfil necessário..."

  bash "$ROOT/scripts/ia" "$AGENT_PROFILE"

  agent_model_loaded \
    || fail "O perfil foi iniciado, mas $AGENT_MODEL_IDENTIFIER não apareceu em 'lms ps'."
}

ensure_api() {
  curl -fsS \
    "$OPENCODE_LMSTUDIO_BASE_URL/models" \
    >/dev/null \
    || fail "LM Studio não respondeu em $OPENCODE_LMSTUDIO_BASE_URL"
}

show_doctor() {
  printf '\n=== Coding Agent ===\n'
  printf 'OpenCode:       '
  opencode --version

  printf '\n=== Configuração ===\n'
  printf 'Projeto atual:  %s\n' "$PWD"
  printf 'Modelo:         %s\n' "$AGENT_MODEL"
  printf 'Perfil físico:  %s\n' "$AGENT_PROFILE"
  printf 'Config:         %s\n' "$OPENCODE_CONFIG"
  printf 'Config dir:     %s\n' "$OPENCODE_CONFIG_DIR"
  printf 'LM Studio:      %s\n' "$OPENCODE_LMSTUDIO_BASE_URL"

  printf '\n=== Modelo carregado ===\n'
  lms ps || true

  printf '\n=== API ===\n'

  if curl -fsS "$OPENCODE_LMSTUDIO_BASE_URL/models" >/dev/null; then
    printf 'LM Studio API:  OK\n'
  else
    printf 'LM Studio API:  INDISPONÍVEL\n'
  fi
}

usage() {
  cat <<'TXT'
Uso:

  ia agent
      Abre o OpenCode interativo em modo PLAN.

  ia agent plan
      Abre o OpenCode interativo em modo PLAN.
      Ideal para entender e planejar antes de alterar código.

  ia agent build
      Abre o OpenCode interativo em modo BUILD.
      Pode implementar alterações, respeitando as permissões configuradas.

  ia agent run plan "tarefa"
      Executa uma tarefa de planejamento sem interface interativa.

  ia agent run build "tarefa"
      Executa uma tarefa de implementação sem interface interativa.

  ia agent doctor
      Diagnóstico da integração OpenCode + LM Studio.

Importante:

  O projeto utilizado pelo agente é sempre o diretório atual.

  Exemplo:

      cd ~/Documentos/projetos/orbiafly
      ia agent
TXT
}

main() {
  require_command opencode
  require_command lms
  require_command curl
  require_command ip

  [[ -f "$OPENCODE_CONFIG_FILE" ]] \
    || fail "Configuração OpenCode não encontrada: $OPENCODE_CONFIG_FILE"

  setup_environment

  local command="${1:-plan}"

  case "$command" in
    plan|build)
      ensure_agent_model
      ensure_api

      info "Projeto: $PWD"
      info "Agente: $command"
      info "Modelo: $AGENT_MODEL"

      exec opencode \
        --model "$AGENT_MODEL" \
        --agent "$command"
      ;;

    run)
      shift

      [[ $# -ge 2 ]] \
        || fail 'Uso: ia agent run <plan|build> "tarefa"'

      local agent="$1"
      shift

      case "$agent" in
        plan|build) ;;
        *)
          fail "Agente inválido: $agent. Use plan ou build."
          ;;
      esac

      ensure_agent_model
      ensure_api

      info "Projeto: $PWD"
      info "Agente: $agent"
      info "Modelo: $AGENT_MODEL"

      exec opencode run \
        --model "$AGENT_MODEL" \
        --agent "$agent" \
        "$@"
      ;;

    doctor)
      show_doctor
      ;;

    -h|--help|help)
      usage
      ;;

    *)
      fail "Comando desconhecido: $command"
      ;;
  esac
}

main "$@"
