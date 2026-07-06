#!/bin/bash
# Opera o HubSaaS do usuário operador (padrão: celio) sem duplicar processos.
#
# O igor (ou outro delegado) roda este script; ele reencaminha para o celio via sudo.
# O celio também pode rodar diretamente.
#
# Uso:
#   bash ~/debian/scripts/operator/hubsaas-op.sh update
#   bash ~/debian/debian hubsaas-op status
#
# Variáveis:
#   HUBSAAS_OPERATOR_USER=celio   usuário que possui ~/hubsaas e os units ngrok

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/debian-root.sh
source "$SCRIPT_DIR/../lib/debian-root.sh"
# shellcheck source=../lib/hubsaas-operator.sh
source "$SCRIPT_DIR/../lib/hubsaas-operator.sh"

OP_SCRIPT="$SCRIPT_DIR/hubsaas-op.sh"
OPERATOR_DEBIAN="$(hubsaas_operator_debian_root)"

if ! hubsaas_is_operator; then
  if [ -z "${HUBSAAS_OP_DELEGATED:-}" ]; then
    if ! id "$HUBSAAS_OPERATOR_USER" &>/dev/null; then
      echo "ERRO: usuário operador '$HUBSAAS_OPERATOR_USER' não existe." >&2
      exit 1
    fi
    if [ ! -x "$OPERATOR_DEBIAN/scripts/operator/hubsaas-op.sh" ] && \
       [ ! -f "$OPERATOR_DEBIAN/scripts/operator/hubsaas-op.sh" ]; then
      echo "ERRO: repo debian do operador não encontrado em $OPERATOR_DEBIAN" >&2
      exit 1
    fi
    export HUBSAAS_OP_DELEGATED=1
    exec sudo -u "$HUBSAAS_OPERATOR_USER" \
      HUBSAAS_OP_DELEGATED=1 \
      HUBSAAS_OPERATOR_USER="$HUBSAAS_OPERATOR_USER" \
      bash "$OPERATOR_DEBIAN/scripts/operator/hubsaas-op.sh" "$@"
  fi
  echo "ERRO: delegação para '$HUBSAAS_OPERATOR_USER' falhou (sudo?)." >&2
  echo "      Rode: sudo bash $OPERATOR_DEBIAN/scripts/operator/install-operator-sudoers.sh igor" >&2
  exit 1
fi

HUBSAAS_DIR="${HUBSAAS_DIR:-$(hubsaas_operator_hubsaas_dir)}"
DEBIAN_ROOT="$OPERATOR_DEBIAN"

cmd="${1:-help}"
shift || true

stop_app_processes() {
  local pattern stopped=0

  if sudo -n systemctl stop hubsaas 2>/dev/null; then
    echo "  [ok] systemd hubsaas parado"
  fi

  for pattern in \
    '.build/apps/backend/main' \
    'apps/frontend/node_modules/.bin/vite' \
    'vite/bin/vite.js' \
    'nest.js start' \
    '@nestjs/cli' \
    'turbo run dev' \
    'pnpm dev'; do
    if pgrep -u "$(id -u)" -f "$pattern" >/dev/null 2>&1; then
      pkill -u "$(id -u)" -f "$pattern" 2>/dev/null || true
      stopped=$((stopped + 1))
    fi
  done

  sleep 2
  if [ "$stopped" -gt 0 ]; then
    echo "  [ok] processos do app encerrados ($stopped padrão(ões))"
  else
    echo "  [ok] nenhum processo do app em execução (usuário $(id -un))"
  fi
}

start_app_processes() {
  local backend_log="/tmp/hubsaas-backend.log"
  local frontend_log="/tmp/hubsaas-frontend.log"

  cd "$HUBSAAS_DIR/apps/backend"
  NODE_PATH=./node_modules:../../node_modules \
    nohup node ../../.build/apps/backend/main.js > "$backend_log" 2>&1 &
  disown 2>/dev/null || true
  echo "  [ok] backend → $backend_log"

  cd "$HUBSAAS_DIR/apps/frontend"
  nohup pnpm dev > "$frontend_log" 2>&1 &
  disown 2>/dev/null || true
  echo "  [ok] frontend → $frontend_log"

  if systemctl is-enabled hubsaas &>/dev/null && sudo -n systemctl start hubsaas 2>/dev/null; then
    echo "  [ok] systemd hubsaas iniciado"
  fi
}

restart_ngrok() {
  local env
  env="$(hubsaas_operator_user_env)"
  # shellcheck disable=SC2086
  if env $env systemctl --user is-enabled hubsaas-backend &>/dev/null; then
    env $env systemctl --user restart hubsaas-backend hubsaas-frontend
    echo "  [ok] ngrok (backend + frontend) reiniciado"
  elif env $env systemctl --user is-enabled hubsaas-ngrok &>/dev/null; then
    env $env systemctl --user restart hubsaas-ngrok
    echo "  [ok] ngrok (legado) reiniciado"
  else
    echo "  [!!] nenhum unit ngrok habilitado para $(id -un)"
    return 1
  fi
}

show_status() {
  echo "Operador: $(id -un) (uid $(id -u))"
  echo "HubSaaS:  $HUBSAAS_DIR"
  echo ""
  echo "== Portas =="
  ss -tlnp 2>/dev/null | grep -E '3020|3021' | sed 's/^/  /' || echo "  (nenhuma porta 3020/3021)"
  echo ""
  echo "== Saúde =="
  if curl -sf -o /dev/null "http://127.0.0.1:3021/v1/health" 2>/dev/null; then
    echo "  [ok] backend http://127.0.0.1:3021/v1/health"
  else
    echo "  [!!] backend sem resposta"
  fi
  if curl -sf -o /dev/null "http://127.0.0.1:3020/" 2>/dev/null; then
    echo "  [ok] frontend http://127.0.0.1:3020/"
  else
    echo "  [!!] frontend sem resposta"
  fi
  echo ""
  bash "$DEBIAN_ROOT/scripts/ngrok/ngrok-status.sh"
}

case "$cmd" in
  update)
    echo "HubSaaS — update (como $(id -un))"
    bash "$DEBIAN_ROOT/scripts/deploy/update.sh" "$@"
    ;;
  apply-env)
    echo "HubSaaS — apply-vps-env (como $(id -un))"
    bash "$DEBIAN_ROOT/scripts/deploy/apply-vps-env.sh" "$@"
    ;;
  stop)
    echo "HubSaaS — parar app (como $(id -un))"
    stop_app_processes
    ;;
  start)
    echo "HubSaaS — subir app (como $(id -un))"
    start_app_processes
    sleep 5
    show_status
    ;;
  restart)
    echo "HubSaaS — reiniciar app + ngrok (como $(id -un))"
    stop_app_processes
    start_app_processes
    restart_ngrok || true
    sleep 5
    show_status
    ;;
  restart-app)
    echo "HubSaaS — reiniciar só app (como $(id -un))"
    stop_app_processes
    start_app_processes
    sleep 5
    show_status
    ;;
  restart-ngrok)
    echo "HubSaaS — reiniciar ngrok (como $(id -un))"
    restart_ngrok
    bash "$DEBIAN_ROOT/scripts/ngrok/ngrok-status.sh"
    ;;
  restart-systemd)
    echo "HubSaaS — systemctl restart hubsaas"
    sudo systemctl restart hubsaas
    sudo systemctl status hubsaas --no-pager || true
    ;;
  status|ngrok-status)
    show_status
    ;;
  help|-h|--help|"")
    cat <<EOF
HubSaaS operator — comandos executados como $HUBSAAS_OPERATOR_USER (sem duplicar processos).

Delegados (ex.: igor) rodam este script; o sudo reencaminha para $HUBSAAS_OPERATOR_USER.

  update            git pull, build, migrations, restart (update.sh)
  apply-env         copia env-servidor/ para ~/hubsaas
  stop              para backend, frontend e systemd hubsaas
  start             sobe backend + frontend (sem git pull)
  restart           stop + start + reinicia ngrok
  restart-app       stop + start (sem ngrok)
  restart-ngrok     reinicia túneis ngrok (systemctl --user)
  restart-systemd   sudo systemctl restart hubsaas
  status            portas, health e ngrok

Instalação sudo (uma vez, como root):
  sudo bash $DEBIAN_ROOT/scripts/operator/install-operator-sudoers.sh igor

Uso:
  bash $OP_SCRIPT update
  bash ~/debian/debian hubsaas-op status
EOF
    ;;
  *)
    echo "Comando desconhecido: $cmd" >&2
    echo "Rode: bash $OP_SCRIPT help" >&2
    exit 1
    ;;
esac
