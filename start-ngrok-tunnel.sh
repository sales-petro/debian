#!/bin/bash
# Inicia túnel ngrok: backend (3021) ou frontend (3020)

set -euo pipefail

ROLE="${1:-}"
CONFIG_DIR="$HOME/.config/ngrok"
NGROK_BIN="$HOME/bin/ngrok"

case "$ROLE" in
  backend)
    PORT=3021
    CONFIG="$CONFIG_DIR/backend.yml"
    ;;
  frontend)
    PORT=3020
    CONFIG="$CONFIG_DIR/frontend.yml"
    ;;
  *)
    echo "Uso: $0 backend|frontend"
    exit 1
    ;;
esac

if [ ! -f "$CONFIG" ]; then
  echo "Config não encontrada: $CONFIG"
  exit 1
fi

exec "$NGROK_BIN" http "$PORT" \
  --config "$CONFIG" \
  --log stdout
