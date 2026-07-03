#!/bin/bash
# Configura stack completa: nginx :80 + ngrok → nginx + env HubSaaS
# Uso: ./setup-nginx-stack.sh [URL_PUBLICA_NGROK]

set -euo pipefail

# shellcheck source=../lib/debian-root.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/debian-root.sh"
NGINX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUBLIC_URL="${1:-https://cytoplasm-quicken-asparagus.ngrok-free.dev}"

echo "== 1/5 Variáveis de ambiente =="
"$DEBIAN_ROOT/scripts/env/configure-hubsaas-env.sh" "$PUBLIC_URL"

echo ""
echo "== 2/5 Vite (proxy + allowedHosts) =="
python3 "$DEBIAN_ROOT/scripts/patches/patch-vite-nginx.py"

echo ""
echo "== 3/5 Nginx =="
if sudo -n true 2>/dev/null; then
  sudo "$NGINX_DIR/install-nginx.sh"
else
  echo "sudo pede senha — rode manualmente:"
  echo "  sudo $NGINX_DIR/install-nginx.sh"
fi

echo ""
echo "== 4/5 Ngrok =="
mkdir -p "$HOME/.config/ngrok"

if curl -sf -o /dev/null "http://127.0.0.1/v1/health" 2>/dev/null; then
  echo "Nginx hubsaas OK → ngrok na porta 80"
  echo 80 > "$HOME/.config/ngrok/hubsaas-port"
else
  echo "Nginx hubsaas ainda não configurado → ngrok temporário na porta 3020 (vite proxy /v1/)"
  echo "Depois de: sudo $NGINX_DIR/install-nginx.sh"
  echo "Rode: $NGINX_DIR/activate-ngrok-nginx.sh"
  echo 3020 > "$HOME/.config/ngrok/hubsaas-port"
fi

if systemctl --user is-enabled hubsaas-ngrok &>/dev/null; then
  systemctl --user restart hubsaas-ngrok
else
  echo "hubsaas-ngrok não instalado. Rode install-ngrok.sh primeiro."
fi

echo ""
echo "== 5/5 HubSaaS (systemd) =="
pkill -f "node ../../.build/apps/backend/main.js" 2>/dev/null || true
pkill -f "vite/bin/vite" 2>/dev/null || true
sleep 2

if sudo -n systemctl restart hubsaas 2>/dev/null; then
  sleep 8
  sudo systemctl status hubsaas --no-pager || true
else
  echo "Iniciando hubsaas manualmente (sudo indisponível)..."
  cd "$HOME/hubsaas"
  nohup pnpm dev > /tmp/hubsaas-dev.log 2>&1 &
  sleep 10
fi

echo ""
echo "== Verificação =="
ss -tln | grep -E ':80|:3020|:3021' || true
curl -s -o /dev/null -w "nginx /       → %{http_code}\n" http://127.0.0.1/ || true
curl -s -o /dev/null -w "nginx /v1/health → %{http_code}\n" http://127.0.0.1/v1/health || true
echo ""
"$DEBIAN_ROOT/scripts/ngrok/ngrok-port.sh" status 2>/dev/null || true
