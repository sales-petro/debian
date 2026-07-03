# Login / diagnóstico (`scripts/login/`)

Testes de autenticação contra backend, proxy Vite e ngrok.

| Script | Descrição |
|--------|-----------|
| `test-vite-proxy.py` | login via :3020, backend :3021, ngrok frontend |
| `test-tenant-slug.py` | valida header `X-Tenant-Slug` |
| `test-ngrok-header.py` | ngrok com `ngrok-skip-browser-warning` |
| `test-login.py`, `test-login-full.py` | fluxos parciais/completos |
| `check-user.py`, `check-password.py`, `check-tokens.py` | diagnóstico banco/tokens |
| `diag-login-remote.sh` | login remoto via SSH |

Credenciais: `platform@hubsaas.local` / `demo1234` / tenant `hubsaas`
