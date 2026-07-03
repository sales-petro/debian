#!/bin/bash
# Configura .env para acesso direto via nsys.ddns.net (portas 3020/3021).
# Uso: ./configure-hubsaas-ddns.sh [URL_PUBLICA]
# Ex.: ./configure-hubsaas-ddns.sh http://nsys.ddns.net:3020

set -euo pipefail

PUBLIC_URL="${1:-http://nsys.ddns.net:3020}"
PUBLIC_URL="${PUBLIC_URL%/}"

HUBSAAS_DIR="${HUBSAAS_DIR:-$HOME/hubsaas}"
BACKEND_ENV="$HUBSAAS_DIR/apps/backend/.env"
FRONTEND_ENV="$HUBSAAS_DIR/apps/frontend/.env"
DEFAULT_TENANT="${DEFAULT_TENANT_SLUG:-hubsaas}"

set_env_var() {
  local file="$1"
  local key="$2"
  local value="$3"

  if [ ! -f "$file" ]; then
    echo "Arquivo não encontrado: $file"
    exit 1
  fi

  if grep -q "^${key}=" "$file"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

echo "== Backend =="
set_env_var "$BACKEND_ENV" "PORT" "3021"
set_env_var "$BACKEND_ENV" "FRONTEND_URL" "$PUBLIC_URL"

echo "== Frontend =="
set_env_var "$FRONTEND_ENV" "PORT" "3020"
set_env_var "$FRONTEND_ENV" "VITE_API_URL" "/v1/"
set_env_var "$FRONTEND_ENV" "VITE_DEFAULT_TENANT_SLUG" "$DEFAULT_TENANT"

echo ""
echo "Configurado:"
echo "  FRONTEND_URL=$PUBLIC_URL"
echo "  VITE_API_URL=/v1/"
echo "  VITE_DEFAULT_TENANT_SLUG=$DEFAULT_TENANT"
echo ""
echo "Reinicie o hubsaas: sudo systemctl restart hubsaas"
echo "Ou, se usar pnpm dev manual: pkill -f vite; pkill -f 'main.js'; e suba de novo."
