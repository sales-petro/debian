#!/bin/bash
# Instala ngrok com 2 túneis separados (tokens diferentes).
#
# Uso: ./install-ngrok-dual.sh [TOKEN_BACKEND] [TOKEN_FRONTEND]
#
# Serviços:
#   hubsaas-backend  → ngrok http 3021  (API)
#   hubsaas-frontend → ngrok http 3020  (Vite)

set -euo pipefail

BACKEND_TOKEN="${1:-3F5idwfF14BcxOEc3zdmV2XuX8D_5hDKYJfmbdakMkzp7HCvP}"
FRONTEND_TOKEN="${2:-3FBjaECT0CxGUiX80iejizrXLOp_678UUSQTi5s4nkpwHtPCy}"

BIN_DIR="$HOME/bin"
CONFIG_DIR="$HOME/.config/ngrok"
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$USER_SYSTEMD_DIR"
export PATH="$BIN_DIR:$PATH"

echo "== Baixando ngrok =="
if ! command -v ngrok &>/dev/null; then
  TMP="$(mktemp -d)"
  curl -fsSL "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz" \
    | tar -xz -C "$TMP"
  install -m 755 "$TMP/ngrok" "$BIN_DIR/ngrok"
  rm -rf "$TMP"
fi
echo "ngrok: $($BIN_DIR/ngrok version)"

write_config() {
  local file="$1"
  local token="$2"
  local web_addr="$3"
  cat > "$file" <<EOF
version: "3"
agent:
  authtoken: ${token}
  web_addr: ${web_addr}
EOF
  chmod 600 "$file"
}

echo "== Configurando tokens =="
write_config "$CONFIG_DIR/backend.yml" "$BACKEND_TOKEN" "127.0.0.1:4040"
write_config "$CONFIG_DIR/frontend.yml" "$FRONTEND_TOKEN" "127.0.0.1:4041"

chmod +x "$SCRIPT_DIR/wait-ngrok-port.sh" "$SCRIPT_DIR/start-ngrok-tunnel.sh" "$SCRIPT_DIR/ngrok-status.sh"

install_unit() {
  local role="$1"
  local src="$SCRIPT_DIR/hubsaas-${role}.service"
  local dst="$USER_SYSTEMD_DIR/hubsaas-${role}.service"
  sed -e "s|__HOME__|$HOME|g" "$src" > "$dst"
}

echo "== Instalando serviços systemd =="
install_unit backend
install_unit frontend

systemctl --user disable hubsaas-ngrok 2>/dev/null || true
systemctl --user stop hubsaas-ngrok 2>/dev/null || true

systemctl --user daemon-reload
systemctl --user enable hubsaas-backend hubsaas-frontend
systemctl --user restart hubsaas-backend hubsaas-frontend

if command -v loginctl &>/dev/null && loginctl show-user "$USER" -p Linger 2>/dev/null | grep -q "yes"; then
  echo "Linger ativo: serviços sobem no boot."
else
  echo ""
  echo "AVISO: para boot sem login, rode UMA VEZ:"
  echo "  sudo ~/debian/enable-ngrok-boot.sh"
fi

echo ""
sleep 5
"$SCRIPT_DIR/ngrok-status.sh"
