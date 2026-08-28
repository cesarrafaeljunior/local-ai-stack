#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/.env"
ENV_EXAMPLE="$ROOT/.env.example"

info() { printf '\033[1;34m[local-ai]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warning]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || fail "Dependência ausente: $1"
}

info "Validando dependências básicas..."
require curl
require python3
require openssl
require docker

docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 não encontrado (comando: docker compose)."

if ! command -v lms >/dev/null 2>&1; then
  warn "LM Studio/llmster (lms) não encontrado."
  read -r -p "Instalar llmster pelo instalador oficial do LM Studio agora? [y/N] " answer
  case "${answer:-N}" in
    y|Y)
      curl -fsSL https://lmstudio.ai/install.sh | bash
      export PATH="$HOME/.lmstudio/bin:$PATH"
      ;;
    *)
      fail "Instale o LM Studio/llmster e execute o bootstrap novamente."
      ;;
  esac
fi

command -v lms >/dev/null 2>&1 || fail "O comando lms ainda não está disponível no PATH."

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  secret="$(openssl rand -hex 32)"
  python3 - "$ENV_FILE" "$secret" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
secret = sys.argv[2]
text = p.read_text()
text = text.replace("WEBUI_SECRET_KEY=\n", f"WEBUI_SECRET_KEY={secret}\n")
p.write_text(text)
PY
  chmod 600 "$ENV_FILE"
  info ".env criado com WEBUI_SECRET_KEY aleatória."
else
  info ".env existente preservado."
fi

mkdir -p "$ROOT/data/open-webui" "$ROOT/backups" "$HOME/.local/bin"

ln -sfn "$ROOT/scripts/ia" "$HOME/.local/bin/ia"
chmod +x "$ROOT/scripts/ia" "$ROOT/scripts/"*.sh

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) warn "~/.local/bin não está no PATH atual. Reabra o terminal ou adicione-o ao PATH." ;;
esac

info "Validando Docker Compose..."
(
  cd "$ROOT"
  docker compose config >/dev/null
)

info "Baixando a imagem do Open WebUI..."
(
  cd "$ROOT"
  docker compose pull
)

info "Iniciando llmster..."
lms daemon up >/dev/null || true

info "Bootstrap concluído."
printf '\nPróximos comandos:\n'
printf '  ia doctor\n'
printf '  ia install work   # se o Qwen3 8B ainda não estiver instalado\n'
printf '  ia work\n'
printf '  ia web\n'
