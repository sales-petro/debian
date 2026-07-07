# env-servidor/ — segredos locais (gitignored)

Esta pasta **não vai para o git**. Contém os `.env` reais do VPS.

## Setup inicial

```bash
cp -r env-servidor.example env-servidor
cp env-servidor.example/apps/backend/.env.example env-servidor/apps/backend/.env
cp env-servidor.example/apps/frontend/.env.example env-servidor/apps/frontend/.env
```

# Templates versionados: [env-servidor.example/README.md](../env-servidor.example/README.md)

## Arquivos locais (gitignored)

| Arquivo | Conteúdo |
|---------|----------|
| `apps/backend/.env` | Postgres, JWT, fiscal, URLs ngrok/ddns |
| `apps/frontend/.env` | Vite, tenant slug |
| `ngrok.env` | `NGROK_BACKEND_TOKEN`, `NGROK_FRONTEND_TOKEN` |

Aplicar no VPS:

```bash
bash scripts/deploy/apply-vps-env.sh
```
