#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/.env"
MODELS_FILE="$ROOT/config/open-webui/models.json"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

OPEN_WEBUI_PORT="${OPEN_WEBUI_PORT:-3000}"
OPEN_WEBUI_API_KEY="${OPEN_WEBUI_API_KEY:-}"
BASE_URL="http://localhost:${OPEN_WEBUI_PORT}"

fail() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

[[ -n "$OPEN_WEBUI_API_KEY" ]] || fail "OPEN_WEBUI_API_KEY não configurada no .env."

mkdir -p "$(dirname "$MODELS_FILE")"
[[ -f "$MODELS_FILE" ]] || printf '[]\n' > "$MODELS_FILE"

auth=(-H "Authorization: Bearer ${OPEN_WEBUI_API_KEY}")
json_header=(-H "Content-Type: application/json")

payload() {
  python3 - "$MODELS_FILE" <<'PY'
import json,sys
with open(sys.argv[1],encoding="utf-8") as f: models=json.load(f)
if not isinstance(models,list): raise SystemExit("models.json deve conter um array.")
print(json.dumps({"models":models},ensure_ascii=False))
PY
}

case "${1:-}" in
  export)
    tmp="$(mktemp)"
    curl -fsS "${auth[@]}" "$BASE_URL/api/v1/models/export" | python3 -m json.tool > "$tmp"
    mv "$tmp" "$MODELS_FILE"
    ok "Presets exportados para $MODELS_FILE"
    ;;
  import)
    data="$(payload)"
    curl -fsS -X POST "${auth[@]}" "${json_header[@]}" -d "$data" "$BASE_URL/api/v1/models/import" >/dev/null
    ok "Presets importados de forma aditiva."
    ;;
  sync)
    count="$(python3 - "$MODELS_FILE" <<'PY'
import json,sys
with open(sys.argv[1],encoding="utf-8") as f:data=json.load(f)
print(len(data) if isinstance(data,list) else -1)
PY
)"
    [[ "$count" -gt 0 ]] || fail "Recusando sync com lista vazia."
    data="$(payload)"
    curl -fsS -X POST "${auth[@]}" "${json_header[@]}" -d "$data" "$BASE_URL/api/v1/models/sync" >/dev/null
    ok "Presets sincronizados."
    ;;
  *) echo "Uso: $0 {export|import|sync}"; exit 1 ;;
esac
