# Patches (`scripts/patches/`)

Referência para alterações pontuais no repo `hubsaas` (incorporar via PR quando possível).

| Script | Alvo |
|--------|------|
| `patch-vite-nginx.py` | `vite.config.ts` — proxy `/v1/` + allowedHosts ngrok |
| `patch-auth-jti.py` | `auth.service.ts` — JTI refresh tokens |
| `patch-backend.py`, `fix-start.py` | utilitários legados |

**Não rodar em CI** — editam arquivos em `~/hubsaas` diretamente.
