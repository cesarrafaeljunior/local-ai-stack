#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

BACKUP_ROOT="$ROOT/backups/private"
OPEN_WEBUI_CONTAINER="${OPEN_WEBUI_CONTAINER:-local-ai-open-webui}"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_NAME="local-ai-stack-full-$TIMESTAMP"

WORKDIR="$(mktemp -d)"
STAGE="$WORKDIR/$BACKUP_NAME"
PLAIN_ARCHIVE="$WORKDIR/$BACKUP_NAME.tar.gz"

FINAL_ARCHIVE="$BACKUP_ROOT/$BACKUP_NAME.tar.gz.gpg"
CHECKSUM_FILE="$FINAL_ARCHIVE.sha256"

WEBUI_WAS_RUNNING=0

info() {
  printf '\n==> %s\n' "$*"
}

ok() {
  printf 'OK: %s\n' "$*"
}

warn() {
  printf 'AVISO: %s\n' "$*" >&2
}

fail() {
  printf 'ERRO: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 \
    || fail "Comando obrigatório não encontrado: $1"
}

restart_webui_if_needed() {
  if [[ "$WEBUI_WAS_RUNNING" == "1" ]]; then
    info "Reiniciando Open WebUI..."
    if docker start "$OPEN_WEBUI_CONTAINER" >/dev/null 2>&1; then
      ok "Open WebUI reiniciado."
    else
      warn "Não foi possível reiniciar o container $OPEN_WEBUI_CONTAINER."
    fi
  fi
}

cleanup() {
  local exit_code=$?
  trap - EXIT
  restart_webui_if_needed
  rm -rf "$WORKDIR"
  exit "$exit_code"
}

trap cleanup EXIT

prepare_directories() {
  mkdir -p "$BACKUP_ROOT"
  mkdir -p \
    "$STAGE/open-webui" \
    "$STAGE/repository" \
    "$STAGE/opencode" \
    "$STAGE/system"
}

stop_webui_if_running() {
  if ! docker inspect "$OPEN_WEBUI_CONTAINER" >/dev/null 2>&1; then
    info "Container Open WebUI não encontrado; continuando o backup."
    return
  fi

  local running
  running="$(docker inspect -f '{{.State.Running}}' "$OPEN_WEBUI_CONTAINER")"

  if [[ "$running" == "true" ]]; then
    info "Parando Open WebUI temporariamente para obter snapshot consistente..."
    docker stop "$OPEN_WEBUI_CONTAINER" >/dev/null
    WEBUI_WAS_RUNNING=1
    ok "Open WebUI parado temporariamente."
  fi
}

backup_open_webui() {
  info "Salvando dados persistentes do Open WebUI..."

  local source_dir="$ROOT/data/open-webui"

  if [[ ! -d "$source_dir" ]]; then
    warn "Diretório $source_dir não encontrado."
    return
  fi

  # Alguns arquivos podem ter sido criados como root pelo container.
  # Quando o container existe, reutilizamos sua imagem para gerar o tar
  # com acesso suficiente, excluindo apenas o cache regenerável.
  if docker inspect "$OPEN_WEBUI_CONTAINER" >/dev/null 2>&1; then
    local image
    image="$(docker inspect -f '{{.Config.Image}}' "$OPEN_WEBUI_CONTAINER")"

    docker run --rm \
      -v "$source_dir:/source:ro" \
      -v "$STAGE/open-webui:/backup" \
      --entrypoint /bin/sh \
      "$image" \
      -c 'tar -C /source --exclude="./cache" -czf /backup/open-webui-data.tar.gz . && chmod 0644 /backup/open-webui-data.tar.gz'

    ok "Open WebUI salvo (cache regenerável ignorado)."
    return
  fi

  tar \
    -C "$source_dir" \
    --exclude='./cache' \
    -czf "$STAGE/open-webui/open-webui-data.tar.gz" \
    .

  ok "Open WebUI salvo usando fallback local."
}

backup_env() {
  info "Salvando configuração privada..."

  if [[ -f "$ROOT/.env" ]]; then
    cp "$ROOT/.env" "$STAGE/private.env"
    chmod 600 "$STAGE/private.env"
    ok ".env incluído no backup criptografado."
  else
    warn ".env não encontrado."
  fi
}

backup_repository() {
  info "Salvando estado do repositório Git..."

  if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    warn "$ROOT não é um repositório Git."
    return
  fi

  git -C "$ROOT" status --short --branch \
    > "$STAGE/repository/git-status.txt"

  git -C "$ROOT" diff --binary \
    > "$STAGE/repository/working-tree.patch"

  git -C "$ROOT" diff --cached --binary \
    > "$STAGE/repository/staged.patch"

  if git -C "$ROOT" rev-parse --verify HEAD >/dev/null 2>&1; then
    git -C "$ROOT" rev-parse HEAD \
      > "$STAGE/repository/commit.txt"

    git -C "$ROOT" bundle create \
      "$STAGE/repository/local-ai-stack.git.bundle" \
      --all

    ok "Histórico Git salvo em bundle."
  else
    warn "Repositório ainda não possui commit; bundle não foi criado."
  fi

  local untracked_list="$WORKDIR/untracked.list"

  git -C "$ROOT" ls-files \
    --others \
    --exclude-standard \
    -z \
    > "$untracked_list"

  if [[ -s "$untracked_list" ]]; then
    (
      cd "$ROOT"
      tar \
        --null \
        -czf "$STAGE/repository/untracked-files.tar.gz" \
        -T "$untracked_list"
    )
    ok "Arquivos não rastreados também foram salvos."
  fi

  ok "Estado do repositório salvo."
}

backup_opencode() {
  info "Salvando configuração e estado do OpenCode..."

  if [[ -d "$HOME/.config/opencode" ]]; then
    tar \
      -C "$HOME/.config" \
      -czf "$STAGE/opencode/config.tar.gz" \
      opencode
    ok "Configuração global do OpenCode salva."
  else
    warn "~/.config/opencode não encontrado."
  fi

  if [[ -d "$HOME/.local/share/opencode" ]]; then
    tar \
      -C "$HOME/.local/share" \
      --exclude='opencode/log' \
      -czf "$STAGE/opencode/state.tar.gz" \
      opencode
    ok "Estado/sessões do OpenCode salvos."
  else
    warn "~/.local/share/opencode não encontrado."
  fi
}

backup_manifests() {
  info "Gerando manifesto do ambiente..."

  {
    printf 'Backup criado em: %s\n\n' "$(date --iso-8601=seconds)"

    printf '=== Kernel ===\n'
    uname -a || true

    printf '\n=== Git ===\n'
    git --version || true

    printf '\n=== Python ===\n'
    python3 --version || true

    printf '\n=== Node ===\n'
    node --version || true

    printf '\n=== npm ===\n'
    npm --version || true

    printf '\n=== Docker ===\n'
    docker --version || true

    printf '\n=== Docker Compose ===\n'
    docker compose version || true

    printf '\n=== OpenCode ===\n'
    opencode --version || true

    printf '\n=== LM Studio CLI ===\n'
    lms --version || true

    printf '\n=== GPG ===\n'
    gpg --version | head -n 2 || true
  } > "$STAGE/system/versions.txt"

  if command -v lms >/dev/null 2>&1; then
    lms ls > "$STAGE/system/lm-studio-models.txt" 2>&1 || true
    lms ps > "$STAGE/system/lm-studio-loaded-models.txt" 2>&1 || true
  fi

  if [[ -f "$ROOT/config/models.json" ]]; then
    cp "$ROOT/config/models.json" "$STAGE/system/models.json"
  fi

  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi > "$STAGE/system/gpu-info.txt" 2>&1 || true
  fi

  docker image ls --digests \
    > "$STAGE/system/docker-images.txt" \
    2>&1 || true

  docker ps -a \
    > "$STAGE/system/docker-containers.txt" \
    2>&1 || true

  if [[ -f /etc/os-release ]]; then
    cp /etc/os-release "$STAGE/system/os-release.txt"
  fi

  ok "Manifesto criado."
}

create_restore_documentation() {
  cat > "$STAGE/RESTORE.md" <<'RESTORE'
# Restauração do Local AI Stack

Este backup é privado e foi criptografado com GPG.

## 1. Repositório

Se existir:

repository/local-ai-stack.git.bundle

clone com:

```bash
git clone repository/local-ai-stack.git.bundle local-ai-stack
```

Os arquivos:

- repository/working-tree.patch
- repository/staged.patch
- repository/untracked-files.tar.gz

preservam alterações que ainda não estavam em commits.

## 2. `.env`

`private.env` é uma cópia do `.env` original.

Depois de recuperar o repositório:

```bash
cp private.env /caminho/do/local-ai-stack/.env
```

## 3. Open WebUI

Crie o diretório:

```bash
mkdir -p /caminho/do/local-ai-stack/data/open-webui
```

Extraia:

```bash
tar -xzf open-webui/open-webui-data.tar.gz \
  -C /caminho/do/local-ai-stack/data/open-webui
```

O cache não faz parte do backup porque pode ser recriado.

## 4. OpenCode

Configuração global:

```bash
mkdir -p ~/.config
tar -xzf opencode/config.tar.gz -C ~/.config
```

Estado/sessões:

```bash
mkdir -p ~/.local/share
tar -xzf opencode/state.tar.gz -C ~/.local/share
```

O estado do OpenCode pode conter credenciais.
Mantenha o backup privado.

## 5. Modelos

Os pesos dos modelos não são incluídos.

Consulte:

- system/lm-studio-models.txt
- system/models.json

Depois reinstale os modelos necessários:

```bash
ia install work
ia install code
```

## 6. Verificação

Depois da restauração:

```bash
ia doctor
ia status
ia agent doctor
```
RESTORE

  ok "Instruções de restauração incluídas."
}

create_archive() {
  info "Compactando backup..."

  tar \
    -C "$WORKDIR" \
    -czf "$PLAIN_ARCHIVE" \
    "$BACKUP_NAME"

  ok "Arquivo temporário criado."
}

encrypt_archive() {
  info "Criptografando backup com GPG..."

  printf '\n'
  printf 'O GPG solicitará uma senha para o backup.\n'
  printf 'Guarde essa senha em um gerenciador de senhas.\n'
  printf 'Sem ela, o backup não poderá ser restaurado.\n\n'

  gpg \
    --symmetric \
    --cipher-algo AES256 \
    --no-symkey-cache \
    --output "$FINAL_ARCHIVE" \
    "$PLAIN_ARCHIVE"

  ok "Backup criptografado."
}

create_checksum() {
  info "Gerando SHA-256..."

  (
    cd "$BACKUP_ROOT"
    sha256sum \
      "$(basename "$FINAL_ARCHIVE")" \
      > "$(basename "$CHECKSUM_FILE")"
  )

  ok "Checksum criado."
}

show_result() {
  printf '\n'
  printf '============================================================\n'
  printf ' BACKUP FULL CONCLUÍDO\n'
  printf '============================================================\n\n'

  printf 'Arquivo criptografado:\n'
  printf '  %s\n\n' "$FINAL_ARCHIVE"

  printf 'Checksum:\n'
  printf '  %s\n\n' "$CHECKSUM_FILE"

  printf 'Tamanho:\n'
  du -h "$FINAL_ARCHIVE" | awk '{print "  " $1}'

  printf '\nGuarde no Google Drive estes dois arquivos:\n'
  printf '  %s\n' "$(basename "$FINAL_ARCHIVE")"
  printf '  %s\n' "$(basename "$CHECKSUM_FILE")"

  printf '\nPara descriptografar futuramente:\n'
  printf '  gpg --output backup.tar.gz --decrypt "%s"\n' \
    "$(basename "$FINAL_ARCHIVE")"

  printf '\nDepois extraia:\n'
  printf '  tar -xzf backup.tar.gz\n\n'
}

main() {
  require_command tar
  require_command gpg
  require_command sha256sum
  require_command git
  require_command docker
  require_command python3

  prepare_directories
  stop_webui_if_running

  backup_open_webui
  backup_env
  backup_repository
  backup_opencode
  backup_manifests
  create_restore_documentation

  create_archive
  encrypt_archive
  create_checksum
  show_result
}

main "$@"
