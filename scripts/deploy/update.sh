#!/bin/bash
# Atualiza o HubSaaS no servidor: git pull → build → migrations → backend + frontend.
#
# Pode rodar de qualquer pasta:
#   bash ~/debian/scripts/deploy/update.sh
#   bash ~/debian/debian update
#
# O código do app sempre vem de ~/hubsaas (repositório git).

set -euo pipefail
set +m   # evita mensagens "Morto"/"Killed" ao encerrar processos

# shellcheck source=../lib/debian-root.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/debian-root.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEBIAN_DIR="$DEBIAN_ROOT"

resolve_hubsaas_dir() {
  if [ -n "${HUBSAAS_DIR:-}" ] && [ -f "$HUBSAAS_DIR/apps/backend/package.json" ]; then
    printf '%s' "$HUBSAAS_DIR"
    return
  fi
  if [ -f "$SCRIPT_DIR/apps/backend/package.json" ]; then
    printf '%s' "$SCRIPT_DIR"
    return
  fi
  if [ -f "$HOME/hubsaas/apps/backend/package.json" ]; then
    printf '%s' "$HOME/hubsaas"
    return
  fi
  echo "ERRO: não encontrei ~/hubsaas (apps/backend/package.json)." >&2
  echo "      Defina: HUBSAAS_DIR=~/hubsaas bash update.sh" >&2
  exit 1
}

HUBSAAS_DIR="$(resolve_hubsaas_dir)"
LOG_FILE="/tmp/hubsaas-update.log"
BACKEND_LOG="/tmp/hubsaas-backend.log"
FRONTEND_LOG="/tmp/hubsaas-frontend.log"
BACKUP_DIR="$HOME/.hubsaas-backup"
LOCAL_FILES=(
  "apps/backend/.env"
  "apps/frontend/.env"
  "apps/frontend/vite.config.ts"
)

: > "$LOG_FILE"

step() {
  echo ""
  echo "────────────────────────────────────────"
  printf " %s\n" "$1"
  echo "────────────────────────────────────────"
}

ok()   { printf "  [ok] %s\n" "$1"; }
warn() { printf "  [!!] %s\n" "$1"; }
info() { printf "  .. %s\n" "$1"; }

run_logged() {
  local label="$1"
  shift
  info "$label (detalhes: $LOG_FILE)"
  {
    echo ""
    echo "===== $label ====="
    echo "===== $(date -Iseconds) ====="
    "$@"
  } >> "$LOG_FILE" 2>&1
  ok "$label"
}

stop_services() {
  local pattern stopped=0

  if sudo -n systemctl stop hubsaas 2>/dev/null; then
    ok "systemd hubsaas parado"
  else
    info "systemd hubsaas não estava ativo (ou sudo indisponível)"
  fi

  for pattern in \
    '.build/apps/backend/main' \
    'apps/frontend/node_modules/.bin/vite' \
  'vite/bin/vite.js' \
    'nest.js start' \
    '@nestjs/cli' \
    'turbo run dev' \
    'pnpm dev'; do
    if pgrep -f "$pattern" >/dev/null 2>&1; then
      pkill -f "$pattern" 2>/dev/null || true
      stopped=$((stopped + 1))
    fi
  done

  sleep 2

  if [ "$stopped" -gt 0 ]; then
    ok "processos encerrados ($stopped padrão(ões))"
  else
    ok "nenhum processo antigo em execução"
  fi
}

echo ""
echo "HubSaaS — update"
info "script:  $DEBIAN_ROOT/scripts/deploy/update.sh"
info "app git: $HUBSAAS_DIR"
info "log:     $LOG_FILE"

if [ ! -d "$HUBSAAS_DIR/.git" ]; then
  echo ""
  warn "ERRO: $HUBSAAS_DIR não é repositório git."
  warn "O git pull deve rodar em ~/hubsaas, não em ~/debian."
  exit 1
fi

cd "$HUBSAAS_DIR"

step "1/6 — Parar serviços"
stop_services

step "2/6 — Git pull (main)"
mkdir -p "$BACKUP_DIR"
for file in "${LOCAL_FILES[@]}"; do
  if [ -f "$file" ]; then
    cp "$file" "$BACKUP_DIR/$(echo "$file" | tr '/' '_')"
  fi
done

git stash push -m "server-local-$(date +%Y%m%d%H%M%S)" -- \
  apps/backend/.env \
  apps/frontend/.env \
  apps/frontend/vite.config.ts \
  docker-compose.yml >> "$LOG_FILE" 2>&1 || true

{
  echo ""
  echo "===== git pull origin main ====="
  git pull origin main
} | tee -a "$LOG_FILE" | tail -5

ok "commit: $(git log -1 --oneline)"

for file in "${LOCAL_FILES[@]}"; do
  backup="$BACKUP_DIR/$(echo "$file" | tr '/' '_')"
  if [ -f "$backup" ]; then
    cp "$backup" "$file"
    ok "restaurado $file"
  fi
done

if grep -q '^VITE_DEFAULT_TENANT_SLUG=demo-alpha' apps/frontend/.env 2>/dev/null; then
  warn "frontend .env usa demo-alpha — login falha no banco restaurado (use hubsaas)"
  warn "corrija: bash ~/debian/scripts/deploy/apply-vps-env.sh && reinicie o frontend"
fi

step "3/6 — Dependências"
run_logged "pnpm install" pnpm install

step "4/6 — Build"
run_logged "pnpm turbo run build" pnpm turbo run build

step "5/6 — Migrations"
run_logged "pnpm migration:run" pnpm migration:run

step "6/6 — Subir backend e frontend"
cd "$HUBSAAS_DIR/apps/backend"
NODE_PATH=./node_modules:../../node_modules \
  nohup node ../../.build/apps/backend/main.js > "$BACKEND_LOG" 2>&1 &
disown 2>/dev/null || true
ok "backend → $BACKEND_LOG"

cd "$HUBSAAS_DIR/apps/frontend"
nohup pnpm dev > "$FRONTEND_LOG" 2>&1 &
disown 2>/dev/null || true
ok "frontend → $FRONTEND_LOG"

if systemctl is-enabled hubsaas &>/dev/null && sudo -n systemctl start hubsaas 2>/dev/null; then
  ok "systemd hubsaas iniciado"
fi

if systemctl --user is-enabled hubsaas-backend &>/dev/null; then
  systemctl --user restart hubsaas-backend hubsaas-frontend >> "$LOG_FILE" 2>&1 && ok "ngrok reiniciado" || true
elif systemctl --user is-enabled hubsaas-ngrok &>/dev/null; then
  systemctl --user restart hubsaas-ngrok >> "$LOG_FILE" 2>&1 && ok "ngrok reiniciado" || true
fi

step "Conferência"
sleep 8

echo ""
info "Portas 3020 / 3021:"
ss -tlnp 2>/dev/null | grep -E '3020|3021' | sed 's/^/       /' || warn "portas ainda não escutando"

echo ""
if curl -sf -o /dev/null "http://127.0.0.1:3021/v1/health" 2>/dev/null; then
  ok "backend health → http://127.0.0.1:3021/v1/health"
else
  warn "backend sem resposta — tail -20 $BACKEND_LOG"
fi

if curl -sf -o /dev/null "http://127.0.0.1:3020/" 2>/dev/null; then
  ok "frontend → http://127.0.0.1:3020/"
else
  warn "frontend sem resposta — tail -20 $FRONTEND_LOG"
fi

echo ""
echo "────────────────────────────────────────"
echo " Deploy concluído"
echo " Log completo: $LOG_FILE"
echo "────────────────────────────────────────"
echo ""
