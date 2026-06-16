#!/bin/bash
# Ngrok aponta para nginx na porta 80 (frontend + backend via /v1/).
# Uso: ./ngrok-port.sh [status]

set -euo pipefail

PORT_FILE="$HOME/.config/ngrok/hubsaas-port"
NGINX_PORT=80

mkdir -p "$(dirname "$PORT_FILE")"

case "${1:-status}" in
  status)
    CURRENT="$(cat "$PORT_FILE" 2>/dev/null || echo "$NGINX_PORT")"
    echo "Destino ngrok: porta $CURRENT (nginx → / :3020, /v1/ :3021)"
    if systemctl --user is-active hubsaas-ngrok &>/dev/null; then
      echo "Serviço: ativo"
      curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null \
        | grep -o '"public_url":"[^"]*"' | head -1 || true
    else
      echo "Serviço: inativo"
    fi
    ;;
  *)
    echo "Ngrok usa nginx na porta 80. Comandos 3020/3021 foram descontinuados."
    echo "Use: $0 status"
    exit 1
    ;;
esac

if [ "$(cat "$PORT_FILE" 2>/dev/null)" != "$NGINX_PORT" ]; then
  echo "$NGINX_PORT" > "$PORT_FILE"
  systemctl --user restart hubsaas-ngrok 2>/dev/null || true
fi
