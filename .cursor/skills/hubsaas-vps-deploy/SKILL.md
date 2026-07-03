---
name: hubsaas-vps-deploy
description: >-
  Deploy e operação do HubSaaS no VPS Debian (~/hubsaas + ~/debian).
  Use ao configurar .env, update, login, ngrok, nginx, PostgreSQL remoto
  ou diagnosticar falhas no VPS 192.168.100.220.
---

# HubSaaS VPS Deploy

## Layout

| Caminho VPS | Conteúdo |
|-------------|----------|
| `~/hubsaas` | App git (SalesPetro/hubsaas) — **não editar scripts aqui** |
| `~/debian` | Este repo — scripts por feature em `scripts/` |
| `~/.hubsaas-backup/` | Backup `.env` restaurado pelo `update.sh` |

Raiz do repo debian: variável `DEBIAN_ROOT` via `scripts/lib/debian-root.sh`.

## Features → pastas

| Tarefa | Pasta | Entrada rápida |
|--------|-------|----------------|
| Deploy | `scripts/deploy/` | `bash ~/debian/scripts/deploy/update.sh` |
| Aplicar .env VPS | `scripts/deploy/` | `bash ~/debian/scripts/deploy/apply-vps-env.sh` |
| Config ngrok/ddns | `scripts/env/` | `scripts/env/configure-hubsaas-env.sh` |
| Testar login | `scripts/login/` | `bash ~/debian/debian test-vite-proxy` |
| Ngrok dual | `scripts/ngrok/` + `systemd/` | `scripts/ngrok/install-ngrok-dual.sh` |
| Nginx | `scripts/nginx/` | `scripts/nginx/install-nginx.sh` |
| Postgres remoto | `scripts/postgres/` | `scripts/postgres/setup-postgres-remote.sh` |

Raiz do repo: apenas `debian` (CLI), `README.md`, pastas `scripts/`, `docs/`, etc.

## Login VPS (banco restaurado)

- E-mail: `platform@hubsaas.local` (**não** `.com`)
- Senha: `demo1234`
- Tenant: `hubsaas` (`demo-alpha` → 401)

Frontend VPS: `VITE_API_URL=/v1/`, `VITE_DEFAULT_TENANT_SLUG=hubsaas`

Backend: `FRONTEND_URL` = URL do **frontend** ngrok (cytoplasm), não o túnel da API (prepaid).

## Fluxo típico

1. Editar `env-servidor/apps/*/.env` (local, gitignored)
2. `scp` para VPS ou `bash apply-vps-env.sh` no servidor
3. Reiniciar frontend (Vite lê `VITE_*` só no startup)
4. Validar: `python3 ~/debian/scripts/login/test-vite-proxy.py`

Se `update.sh` restaurar `demo-alpha`, rodar `apply-vps-env.sh` de novo.

## Restrições

- **Não modificar** código em `~/hubsaas` para fixes de infra — usar `.env`, scripts debian, patches documentados em `scripts/patches/`
- `env-servidor/` contém segredos — nunca commitar
- Após reorganizar paths ngrok, reinstalar units: `bash install-ngrok-dual.sh TOKEN_BE TOKEN_FE`

## Documentação

- [README.md](../../README.md)
- [docs/deploy/hubsaas-vps-login.md](../../docs/deploy/hubsaas-vps-login.md)
- [.cursor/plans/fix-vps-login-env.plan.md](../../plans/fix-vps-login-env.plan.md)
