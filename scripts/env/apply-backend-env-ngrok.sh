#!/bin/bash
# Aplica variáveis fiscais, Shopee Review e ngrok no backend .env do servidor.
# Uso: bash apply-backend-env-ngrok.sh [URL_NGROK]
# Ex.: bash apply-backend-env-ngrok.sh https://cytoplasm-quicken-asparagus.ngrok-free.dev

set -euo pipefail

PUBLIC_URL="${1:-https://cytoplasm-quicken-asparagus.ngrok-free.dev}"
PUBLIC_URL="${PUBLIC_URL%/}"

HUBSAAS_DIR="${HUBSAAS_DIR:-$HOME/hubsaas}"
BACKEND_ENV="$HUBSAAS_DIR/apps/backend/.env"

set_env_var() {
  local file="$1"
  local key="$2"
  local value="$3"
  if grep -q "^${key}=" "$file"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

if [ ! -f "$BACKEND_ENV" ]; then
  echo "ERRO: $BACKEND_ENV não encontrado"
  exit 1
fi

echo "== Atualizando $BACKEND_ENV =="

set_env_var "$BACKEND_ENV" "FISCAL_ENCRYPTION_KEY" "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"
set_env_var "$BACKEND_ENV" "FRONTEND_URL" "$PUBLIC_URL"
set_env_var "$BACKEND_ENV" "SHOPEE_REVIEW_WEBHOOK_BASE_URL" "$PUBLIC_URL"
set_env_var "$BACKEND_ENV" "SHOPEE_REVIEW_ML_REDIRECT_URI" "${PUBLIC_URL}/v1/channels/oauth/mercadolivre/callback"
set_env_var "$BACKEND_ENV" "AUTH_BOOTSTRAP_ENABLED" "false"
set_env_var "$BACKEND_ENV" "AUTH_BOOTSTRAP_AUTO_TENANT" "false"

# Comentários opcionais ML (só adiciona se ainda não existirem)
if ! grep -q "SHOPEE_REVIEW_ML_CLIENT_ID" "$BACKEND_ENV"; then
  cat >> "$BACKEND_ENV" <<'EOF'

# Opcional (só se for testar OAuth ML completo no seed shopee-review)
#SHOPEE_REVIEW_ML_CLIENT_ID=seu_client_id_do_devcenter_ml
#SHOPEE_REVIEW_ML_CLIENT_SECRET=seu_client_secret
EOF
fi

echo ""
echo "Variáveis aplicadas (URL=$PUBLIC_URL):"
grep -E '^(FISCAL_ENCRYPTION_KEY|FRONTEND_URL|SHOPEE_REVIEW_|AUTH_BOOTSTRAP_)' "$BACKEND_ENV" || true
echo ""
echo "Reinicie o backend: sudo systemctl restart hubsaas"
echo "Ou: pkill -f '.build/apps/backend/main.js' e suba de novo."
