#!/bin/bash
# Concede a usuários delegados (ex.: igor) permissão NOPASSWD para operar o HubSaaS
# do usuário operador (padrão: celio), sem duplicar processos.
#
# Uso (como root):
#   sudo bash install-operator-sudoers.sh igor
#   sudo bash install-operator-sudoers.sh igor outro-usuario
#
# Variáveis:
#   HUBSAAS_OPERATOR_USER=celio

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/hubsaas-operator.sh
source "$SCRIPT_DIR/../lib/hubsaas-operator.sh"

if [ "$EUID" -ne 0 ]; then
  echo "Execute com sudo: sudo bash $0 <usuario-delegado> [...]" >&2
  exit 1
fi

if [ "$#" -lt 1 ]; then
  echo "Uso: sudo bash $0 <usuario-delegado> [outro-delegado ...]" >&2
  echo "Ex.: sudo bash $0 igor" >&2
  exit 1
fi

if ! id "$HUBSAAS_OPERATOR_USER" &>/dev/null; then
  echo "ERRO: usuário operador '$HUBSAAS_OPERATOR_USER' não existe." >&2
  exit 1
fi

OPERATOR_HOME="$(hubsaas_operator_home)"
OP_SCRIPT="$OPERATOR_HOME/debian/scripts/operator/hubsaas-op.sh"
SUDOERS_FILE="/etc/sudoers.d/hubsaas-operator"

if [ ! -f "$OP_SCRIPT" ]; then
  echo "ERRO: $OP_SCRIPT não encontrado." >&2
  echo "      Atualize ~/debian no usuário $HUBSAAS_OPERATOR_USER antes de instalar." >&2
  exit 1
fi

chmod 755 "$OP_SCRIPT"

{
  echo "# HubSaaS — delegados operam stack de $HUBSAAS_OPERATOR_USER (gerado por install-operator-sudoers.sh)"
  echo "# Não edite manualmente sem necessidade; reinstale o script para regenerar."
  echo ""
  for delegate in "$@"; do
    if ! id "$delegate" &>/dev/null; then
      echo "ERRO: usuário delegado '$delegate' não existe." >&2
      exit 1
    fi
    usermod -aG sudo "$delegate" 2>/dev/null || true
    echo "$delegate ALL=($HUBSAAS_OPERATOR_USER) NOPASSWD: /bin/bash $OP_SCRIPT *"
    echo "$delegate ALL=(ALL) NOPASSWD: /bin/systemctl stop hubsaas, /bin/systemctl start hubsaas, /bin/systemctl restart hubsaas, /bin/systemctl status hubsaas"
    echo "Defaults:$delegate !requiretty"
    echo ""
  done
} > "$SUDOERS_FILE"

chmod 440 "$SUDOERS_FILE"
visudo -cf "$SUDOERS_FILE"

echo "OK: sudoers instalado em $SUDOERS_FILE"
echo ""
echo "Delegados: $*"
echo "Operador:  $HUBSAAS_OPERATOR_USER"
echo ""
echo "Teste (como delegado):"
echo "  bash $OP_SCRIPT status"
echo "  bash $OP_SCRIPT update"
