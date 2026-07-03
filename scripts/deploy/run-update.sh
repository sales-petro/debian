#!/bin/bash
set -e
cd ~/hubsaas

BACKUP_DIR="$HOME/.hubsaas-backup"
LOCAL_FILES=(
  "apps/backend/.env"
  "apps/frontend/.env"
  "apps/frontend/vite.config.ts"
)

for file in "${LOCAL_FILES[@]}"; do
  backup="$BACKUP_DIR/$(echo "$file" | tr '/' '_')"
  if [ -f "$backup" ]; then
    cp "$backup" "$file"
    echo "Restored $file"
  fi
done

pkill -f 'pnpm dev' 2>/dev/null || true
pkill -f 'nest' 2>/dev/null || true
pkill -f 'vite' 2>/dev/null || true
pkill -f '.build/apps/backend/main' 2>/dev/null || true
sleep 2

echo "== INSTALL DEPENDENCIES =="
pnpm install

echo "== BUILD MONOREPO =="
pnpm turbo run build

echo "== RUN DATABASE MIGRATIONS =="
pnpm migration:run

echo "== START BACKEND =="
cd apps/backend
NODE_PATH=./node_modules:../../node_modules nohup node ../../.build/apps/backend/main.js > /tmp/hubsaas-backend.log 2>&1 &

echo "== START FRONTEND =="
cd ../frontend
nohup pnpm dev > /tmp/hubsaas-frontend.log 2>&1 &

sleep 10
echo "== CHECK PORTS =="
ss -tulpn | grep -E '3020|3021' || true

echo "== BACKEND LOG =="
tail -5 /tmp/hubsaas-backend.log || true

echo "== FRONTEND LOG =="
tail -5 /tmp/hubsaas-frontend.log || true

echo "DONE"
