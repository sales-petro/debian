#!/bin/bash
# Instala config nginx HubSaaS: / → :3020, /v1/ → :3021
# Uso: sudo ./install-nginx.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Execute com sudo: sudo $0"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_SRC="$SCRIPT_DIR/hubsaas.conf"
CONF_DST="/etc/nginx/sites-available/hubsaas"

if [ ! -f "$CONF_SRC" ]; then
  echo "Arquivo não encontrado: $CONF_SRC"
  exit 1
fi

cp "$CONF_SRC" "$CONF_DST"
ln -sf "$CONF_DST" /etc/nginx/sites-enabled/hubsaas

if [ -f /etc/nginx/sites-enabled/default ]; then
  rm -f /etc/nginx/sites-enabled/default
fi

nginx -t
systemctl reload nginx
systemctl enable nginx

echo "Nginx HubSaaS ativo em :80"
echo "  /    → 127.0.0.1:3020 (frontend)"
echo "  /v1/ → 127.0.0.1:3021 (backend)"
