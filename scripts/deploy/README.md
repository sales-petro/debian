# Deploy (`scripts/deploy/`)

| Script | Descrição |
|--------|-----------|
| `update.sh` | git pull → build → migrations → restart backend + frontend |
| `apply-vps-env.sh` | Copia `env-servidor/` → `~/hubsaas` + atualiza `~/.hubsaas-backup/` |
| `run-update.sh` | Update legado (sem git pull) — preferir `update.sh` |

Wrappers removidos da raiz — use `scripts/deploy/update.sh` ou `bash debian update`.
