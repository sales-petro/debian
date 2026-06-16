#!/bin/bash
# Rode APÓS: sudo ~/debian/install-nginx.sh
# Troca ngrok de :3020 (temporário) para :80 (nginx).

set -euo pipefail

echo 80 > "$HOME/.config/ngrok/hubsaas-port"
systemctl --user restart hubsaas-ngrok
sleep 4

echo "Testes locais:"
curl -s -o /dev/null -w "  /           → %{http_code}\n" http://127.0.0.1/
curl -s -o /dev/null -w "  /v1/health  → %{http_code}\n" http://127.0.0.1/v1/health

~/debian/ngrok-port.sh status
