#!/bin/bash
# Atualiza .env do backend e frontend para uso com nginx + ngrok.
# Uso: ./configure-hubsaas-env.sh [URL_PUBLICA]
# Ex.: ./configure-hubsaas-env.sh https://prepaid-untying-capsule.ngrok-free.dev

set -euo pipefail

PUBLIC_URL="${1:-https://prepaid-untying-capsule.ngrok-free.dev}"
PUBLIC_URL="${PUBLIC_URL%/}"

HUBSAAS_DIR="${HUBSAAS_DIR:-$HOME/hubsaas}"
BACKEND_ENV="$HUBSAAS_DIR/apps/backend/.env"
FRONTEND_ENV="$HUBSAAS_DIR/apps/frontend/.env"

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

echo "== Configurando backend =="
set_env_var "$BACKEND_ENV" "PORT" "3021"
set_env_var "$BACKEND_ENV" "FRONTEND_URL" "$PUBLIC_URL"

echo "== Configurando frontend =="
set_env_var "$FRONTEND_ENV" "PORT" "3020"
set_env_var "$FRONTEND_ENV" "VITE_API_URL" "/v1/"

echo ""
echo "Backend:  PORT=3021, FRONTEND_URL=$PUBLIC_URL"
echo "Frontend: PORT=3020, VITE_API_URL=/v1/"
echo ""
echo "Reinicie o hubsaas após alterar: sudo systemctl restart hubsaas"
