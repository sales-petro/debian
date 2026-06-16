#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BACKUP_DIR="$HOME/.hubsaas-backup"
LOCAL_FILES=(
  "apps/backend/.env"
  "apps/frontend/.env"
  "apps/frontend/vite.config.ts"
)

echo "== STOP SYSTEMD =="
sudo systemctl stop hubsaas || true

echo "== KILL ORPHAN PROCESSES =="
sudo pkill -9 -f "pnpm dev" || true
sudo pkill -9 -f "turbo" || true
sudo pkill -9 -f "nest" || true
sudo pkill -9 -f "vite" || true

echo "== GIT UPDATE =="
mkdir -p "$BACKUP_DIR"
for file in "${LOCAL_FILES[@]}"; do
  if [ -f "$file" ]; then
    cp "$file" "$BACKUP_DIR/$(echo "$file" | tr '/' '_')"
  fi
done

git stash push -m "server-test-local-$(date +%Y%m%d%H%M%S)" -- \
  apps/backend/.env \
  apps/frontend/.env \
  apps/frontend/vite.config.ts \
  docker-compose.yml 2>/dev/null || true

git pull origin main

for file in "${LOCAL_FILES[@]}"; do
  backup="$BACKUP_DIR/$(echo "$file" | tr '/' '_')"
  if [ -f "$backup" ]; then
    cp "$backup" "$file"
  fi
done

echo "== INSTALL DEPENDENCIES =="
pnpm install

echo "== BUILD MONOREPO =="
pnpm turbo run build

echo "== RUN DATABASE MIGRATIONS =="
pnpm migration:run

echo "== START SYSTEMD =="
sudo systemctl start hubsaas

if systemctl --user is-enabled hubsaas-backend &>/dev/null; then
  echo "== RESTART NGROK =="
  systemctl --user restart hubsaas-backend hubsaas-frontend || true
elif systemctl --user is-enabled hubsaas-ngrok &>/dev/null; then
  echo "== RESTART NGROK (legado) =="
  systemctl --user restart hubsaas-ngrok || true
fi

echo "== WAIT STARTUP =="
sleep 5

echo "== CHECK PORTS =="
ss -tulpn | grep -E "3020|3021" || true

echo "== STATUS =="
systemctl status hubsaas --no-pager
