#!/bin/bash
# Status dos túneis ngrok backend e frontend.

set -euo pipefail

echo "== hubsaas-backend (:3021) =="
if systemctl --user is-active hubsaas-backend &>/dev/null; then
  echo "Serviço: ativo"
  curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null \
    | grep -o '"public_url":"[^"]*"' | head -1 || echo "(sem URL ainda)"
else
  echo "Serviço: inativo"
  systemctl --user status hubsaas-backend --no-pager 2>/dev/null | tail -3 || true
fi

echo ""
echo "== hubsaas-frontend (:3020) =="
if systemctl --user is-active hubsaas-frontend &>/dev/null; then
  echo "Serviço: ativo"
  curl -s http://127.0.0.1:4041/api/tunnels 2>/dev/null \
    | grep -o '"public_url":"[^"]*"' | head -1 || echo "(sem URL ainda)"
else
  echo "Serviço: inativo"
  systemctl --user status hubsaas-frontend --no-pager 2>/dev/null | tail -3 || true
fi
