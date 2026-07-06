#!/bin/bash
# Instala e configura ddclient para atualizar um hostname No-IP.
# Uso:
#   bash ~/debian/scripts/env/install-noip-ddclient.sh
#   NOIP_LOGIN=usuario NOIP_PASSWORD=senha bash .../install-noip-ddclient.sh hubswp.ddns.net

set -euo pipefail

NOIP_HOSTNAME="${1:-${NOIP_HOSTNAME:-hubswp.ddns.net}}"
NOIP_LOGIN="${NOIP_LOGIN:-petrofuelbusiness@gmail.com}"
NOIP_INTERVAL="${NOIP_INTERVAL:-300}"
NOIP_PASSWORD="${NOIP_PASSWORD:-}"

if [ -z "$NOIP_PASSWORD" ]; then
  echo "Login No-IP: $NOIP_LOGIN"
  echo "Hostname No-IP: $NOIP_HOSTNAME"
  echo ""
  echo "Use a senha/credencial de DDNS do No-IP, nao a autenticacao Google."
  read -r -s -p "Senha/credencial DDNS No-IP: " NOIP_PASSWORD
  echo ""
fi

if [ -z "$NOIP_PASSWORD" ]; then
  echo "Senha/credencial DDNS No-IP obrigatoria." >&2
  exit 1
fi

case "$NOIP_PASSWORD" in
  *"'"*)
    echo "A credencial contem aspas simples. Gere outra DDNS Key no No-IP sem esse caractere." >&2
    exit 1
    ;;
esac

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

if ! command -v ddclient >/dev/null 2>&1; then
  echo "== Instalando ddclient =="
  $SUDO apt-get update
  $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y ddclient curl dnsutils
fi

TMP_CONF="$(mktemp)"
chmod 600 "$TMP_CONF"
cat > "$TMP_CONF" <<EOF
# Gerado por install-noip-ddclient.sh.
daemon=${NOIP_INTERVAL}
syslog=yes
ssl=yes
use=web, web=checkip.dyndns.com/, web-skip='IP Address'
protocol=noip
server=dynupdate.no-ip.com
login=${NOIP_LOGIN}
password='${NOIP_PASSWORD}'
${NOIP_HOSTNAME}
EOF

echo "== Gravando /etc/ddclient.conf =="
$SUDO install -m 600 -o root -g root "$TMP_CONF" /etc/ddclient.conf
rm -f "$TMP_CONF"

if [ -f /etc/default/ddclient ]; then
  $SUDO sed -i \
    -e 's/^run_daemon=.*/run_daemon="true"/' \
    -e "s/^daemon_interval=.*/daemon_interval=\"${NOIP_INTERVAL}\"/" \
    /etc/default/ddclient
fi

echo "== Ativando servico ddclient =="
$SUDO systemctl enable ddclient
$SUDO systemctl restart ddclient

PUBLIC_IP="$(curl -fsS https://api.ipify.org || true)"
DNS_IP="$(getent ahostsv4 "$NOIP_HOSTNAME" | awk 'NR == 1 { print $1 }' || true)"

echo ""
echo "No-IP configurado para: $NOIP_HOSTNAME"
echo "IP publico atual: ${PUBLIC_IP:-nao verificado}"
echo "DNS resolvendo para: ${DNS_IP:-ainda nao propagou}"
echo ""
echo "Verifique com:"
echo "  systemctl status ddclient --no-pager"
echo "  getent ahostsv4 $NOIP_HOSTNAME"
