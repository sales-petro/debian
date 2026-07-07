# Templates .env do VPS (sem segredos)

Copie esta pasta para `env-servidor/` (gitignored) e preencha os valores sensíveis:

```bash
cp -r env-servidor.example env-servidor
# Edite env-servidor/apps/*/.env — nunca commitar
bash scripts/deploy/apply-vps-env.sh
```

| Template | Destino local (gitignored) | Destino no VPS |
|----------|----------------------------|----------------|
| `apps/backend/.env.example` | `env-servidor/apps/backend/.env` | `~/hubsaas/apps/backend/.env` |
| `apps/frontend/.env.example` | `env-servidor/apps/frontend/.env` | idem frontend |

Variáveis sensíveis (só em `env-servidor/`, nunca no git):

- Senha Postgres
- `AUTH_JWT_*_SECRET`, `FISCAL_ENCRYPTION_KEY`
- Tokens ngrok (via `~/.config/ngrok/` ou variáveis de ambiente)
