#!/bin/bash
# Aguarda porta local antes de abrir o túnel ngrok.
# Uso: wait-ngrok-port.sh <porta>

set -euo pipefail

PORT="${1:-}"
if [ -z "$PORT" ]; then
  echo "Uso: $0 <porta>"
  exit 1
fi

for _ in $(seq 1 30); do
  if ss -tln | grep -q ":${PORT} "; then
    exit 0
  fi
  sleep 2
done

echo "Serviço na porta ${PORT} não respondeu a tempo"
exit 1
