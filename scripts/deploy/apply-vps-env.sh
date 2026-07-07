#!/bin/bash
# Copia env-servidor/ para ~/hubsaas e atualiza backup do update.sh.
# Uso: bash apply-vps-env.sh
#      DEBIAN_DIR=~/debian bash apply-vps-env.sh

set -euo pipefail

# shellcheck source=../lib/debian-root.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/debian-root.sh"
DEBIAN_DIR="${DEBIAN_DIR:-$DEBIAN_ROOT}"
HUBSAAS_DIR="${HUBSAAS_DIR:-$HOME/hubsaas}"
BACKUP_DIR="$HOME/.hubsaas-backup"
SRC_BACKEND="$DEBIAN_DIR/env-servidor/apps/backend/.env"
SRC_FRONTEND="$DEBIAN_DIR/env-servidor/apps/frontend/.env"
DST_BACKEND="$HUBSAAS_DIR/apps/backend/.env"
DST_FRONTEND="$HUBSAAS_DIR/apps/frontend/.env"

for f in "$SRC_BACKEND" "$SRC_FRONTEND"; do
  if [ ! -f "$f" ]; then
    echo "ERRO: $f não encontrado"
    echo ""
    echo "Crie a pasta local com segredos (gitignored):"
    echo "  cp -r $DEBIAN_DIR/env-servidor.example $DEBIAN_DIR/env-servidor"
    echo "  cp env-servidor.example/apps/backend/.env.example env-servidor/apps/backend/.env"
    echo "  cp env-servidor.example/apps/frontend/.env.example env-servidor/apps/frontend/.env"
    echo "  # edite env-servidor/apps/*/.env e preencha senhas"
    exit 1
  fi
done

if [ ! -d "$HUBSAAS_DIR/apps/backend" ]; then
  echo "ERRO: $HUBSAAS_DIR não existe"
  exit 1
fi

mkdir -p "$BACKUP_DIR"
cp "$SRC_BACKEND" "$DST_BACKEND"
cp "$SRC_FRONTEND" "$DST_FRONTEND"
cp "$SRC_BACKEND" "$BACKUP_DIR/apps_backend_.env"
cp "$SRC_FRONTEND" "$BACKUP_DIR/apps_frontend_.env"

echo "Aplicado:"
echo "  $DST_BACKEND"
echo "  $DST_FRONTEND"
echo "Backup atualizado em $BACKUP_DIR"
echo ""
grep -E '^(FRONTEND_URL|VITE_API_URL|VITE_DEFAULT_TENANT)' "$DST_BACKEND" "$DST_FRONTEND" 2>/dev/null || true
echo ""
echo "Reinicie backend + frontend (Vite precisa restart para VITE_*):"
echo "  bash ~/debian/scripts/deploy/update.sh"
echo "  ou: pkill -f 'vite|main.js'; cd ~/hubsaas/apps/backend && NODE_PATH=./node_modules:../../node_modules nohup node ../../.build/apps/backend/main.js > /tmp/hubsaas-backend.log 2>&1 &"
echo "      cd ~/hubsaas/apps/frontend && nohup pnpm dev > /tmp/hubsaas-frontend.log 2>&1 &"
