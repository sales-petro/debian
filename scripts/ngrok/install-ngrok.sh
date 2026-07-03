#!/bin/bash
# Instala ngrok (modo usuário, sem sudo) e serviço systemd hubsaas-ngrok.
# Uso: ./install-ngrok.sh <AUTHTOKEN> [porta_inicial]

set -euo pipefail

NGROK_PORT="${2:-${NGROK_PORT:-80}}"
AUTHTOKEN="${1:-${NGROK_AUTHTOKEN:-}}"
BIN_DIR="$HOME/bin"
CONFIG_DIR="$HOME/.config/ngrok"
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/debian-root.sh
source "$SCRIPT_DIR/../lib/debian-root.sh"
SYSTEMD_DIR="$DEBIAN_ROOT/systemd"

if [ -z "$AUTHTOKEN" ]; then
  echo "Uso: $0 <NGROK_AUTHTOKEN> [porta_inicial]"
  exit 1
fi

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

echo "== Configurando =="
echo "$NGROK_PORT" > "$CONFIG_DIR/hubsaas-port"

cat > "$CONFIG_DIR/ngrok.yml" <<EOF
version: "3"
agent:
  authtoken: ${AUTHTOKEN}
EOF
chmod 600 "$CONFIG_DIR/ngrok.yml"

chmod +x "$SCRIPT_DIR/wait-ngrok-port.sh" "$SCRIPT_DIR/start-ngrok.sh" "$SCRIPT_DIR/ngrok-port.sh"

SERVICE_SRC="$SYSTEMD_DIR/hubsaas-ngrok.service"
SERVICE_DST="$USER_SYSTEMD_DIR/hubsaas-ngrok.service"

sed \
  -e "s|__HOME__|$HOME|g" \
  "$SERVICE_SRC" > "$SERVICE_DST"

echo "== Ativando serviço (usuário) =="
systemctl --user daemon-reload
systemctl --user enable hubsaas-ngrok
systemctl --user restart hubsaas-ngrok

if command -v loginctl &>/dev/null && loginctl show-user "$USER" -p Linger 2>/dev/null | grep -q "yes"; then
  echo "Linger ativo: serviço sobe no boot."
else
  echo ""
  echo "AVISO: para iniciar no boot sem login, rode UMA VEZ:"
  echo "  sudo ~/debian/scripts/ngrok/enable-ngrok-boot.sh"
fi

echo ""
sleep 4
"$SCRIPT_DIR/ngrok-port.sh" status
