#!/bin/bash
# Atualiza .env do backend e frontend para uso com DDNS No-IP.
# Uso: ./configure-hubsaas-ddns.sh [URL_PUBLICA]
# Ex.: ./configure-hubsaas-ddns.sh http://hubswp.ddns.net:3020

set -euo pipefail

PUBLIC_URL="${1:-http://hubswp.ddns.net:3020}"
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
    echo "Arquivo nao encontrado: $file" >&2
    exit 1
  fi

  if grep -q "^${key}=" "$file"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

echo "== Configurando backend para DDNS =="
set_env_var "$BACKEND_ENV" "PORT" "3021"
set_env_var "$BACKEND_ENV" "FRONTEND_URL" "$PUBLIC_URL"
set_env_var "$BACKEND_ENV" "SHOPEE_REVIEW_WEBHOOK_BASE_URL" "$PUBLIC_URL"
set_env_var "$BACKEND_ENV" "SHOPEE_REVIEW_ML_REDIRECT_URI" "${PUBLIC_URL}/v1/channels/oauth/mercadolivre/callback"

echo "== Configurando frontend para DDNS =="
set_env_var "$FRONTEND_ENV" "PORT" "3020"
set_env_var "$FRONTEND_ENV" "VITE_API_URL" "/v1/"
set_env_var "$FRONTEND_ENV" "VITE_DEFAULT_TENANT_SLUG" "$DEFAULT_TENANT"

echo ""
echo "Backend:  PORT=3021, FRONTEND_URL=$PUBLIC_URL"
echo "Frontend: PORT=3020, VITE_API_URL=/v1/, VITE_DEFAULT_TENANT_SLUG=$DEFAULT_TENANT"
echo ""
echo "Reinicie o hubsaas apos alterar: sudo systemctl restart hubsaas"
