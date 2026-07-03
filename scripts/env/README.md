# Env (`scripts/env/`)

Ajusta `.env` em `~/hubsaas/apps/{backend,frontend}/`.

| Script | Uso |
|--------|-----|
| `configure-hubsaas-env.sh [URL]` | ngrok frontend (cytoplasm) + tenant `hubsaas` |
| `configure-hubsaas-ddns.sh [URL]` | nsys.ddns.net |
| `apply-backend-env-ngrok.sh [URL]` | só vars fiscais/Shopee no backend |

Templates VPS: `env-servidor/apps/*/.env` (gitignored).
