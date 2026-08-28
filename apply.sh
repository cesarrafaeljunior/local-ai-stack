#!/usr/bin/env bash
set -euo pipefail

UPDATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY="$UPDATE_ROOT/overlay"
TARGET="${1:-$PWD}"

if [[ ! -f "$TARGET/docker-compose.yml" || ! -f "$TARGET/scripts/ia" ]]; then
  echo "ERRO: '$TARGET' não parece ser o local-ai-stack."
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$TARGET/.architecture-v1-backup-$STAMP"
mkdir -p "$BACKUP"

echo "Backup: $BACKUP"

while IFS= read -r -d '' src; do
  rel="${src#$OVERLAY/}"
  dst="$TARGET/$rel"
  if [[ -f "$dst" ]]; then
    mkdir -p "$BACKUP/$(dirname "$rel")"
    cp -a "$dst" "$BACKUP/$rel"
  fi
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
done < <(find "$OVERLAY" -type f -print0)

if [[ -f "$TARGET/prompts/developer.md" ]]; then
  mkdir -p "$BACKUP/prompts"
  cp -a "$TARGET/prompts/developer.md" "$BACKUP/prompts/developer.md"
  rm -f "$TARGET/prompts/developer.md"
fi

chmod +x "$TARGET/scripts/ia" "$TARGET/scripts/webui-models.sh"

bash -n "$TARGET/scripts/ia"
bash -n "$TARGET/scripts/webui-models.sh"
python3 -m json.tool "$TARGET/config/models.json" >/dev/null
python3 -m json.tool "$TARGET/config/open-webui/models.json" >/dev/null

echo
echo "Atualização aplicada."
echo "- .env existente não foi alterado."
echo "- nenhum modelo foi instalado ou removido."
echo "- prompt antigo developer.md foi salvo no backup e removido."
echo
echo "Confira:"
echo "  ia --help"
echo "  ia models"
echo "  ia info work"
echo "  ia prompt work"
echo "  git diff"
