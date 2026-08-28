#!/usr/bin/env bash
set -euo pipefail

echo "=== CPU ==="
lscpu | grep -E "Model name|Nome do modelo|CPU\(s\)|Thread|Core|Núcleo" || true

echo
echo "=== RAM ==="
free -h

echo
echo "=== GPU ==="
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=name,memory.total,driver_version \
    --format=csv,noheader
else
  echo "NVIDIA não detectada"
fi

echo
echo "=== DISCO ==="
df -h /
