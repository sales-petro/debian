#!/bin/bash
# Inicia ngrok na porta definida em ~/.config/ngrok/hubsaas-port

set -euo pipefail

PORT_FILE="$HOME/.config/ngrok/hubsaas-port"
PORT="$(cat "$PORT_FILE" 2>/dev/null || echo 80)"

exec "$HOME/bin/ngrok" http "$PORT" \
  --config "$HOME/.config/ngrok/ngrok.yml" \
  --log stdout
