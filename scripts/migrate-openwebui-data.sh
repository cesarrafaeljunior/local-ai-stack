#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_CONTAINER="${1:-open-webui}"
TARGET="$ROOT/data/open-webui"

if ! docker inspect "$SOURCE_CONTAINER" >/dev/null 2>&1; then
  echo "Container '$SOURCE_CONTAINER' não encontrado."
  echo "Informe o nome correto: $0 <container>"
  exit 1
fi

mkdir -p "$TARGET"

echo "Copiando /app/backend/data do container '$SOURCE_CONTAINER'..."
docker cp "$SOURCE_CONTAINER:/app/backend/data/." "$TARGET/"

echo
echo "Dados copiados para: $TARGET"
echo "O container antigo NÃO foi removido."
echo "Antes de subir o novo stack na mesma porta, pare o antigo:"
echo "  docker stop $SOURCE_CONTAINER"
