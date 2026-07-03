---
name: Fix VPS login via env
overview: "Alinhar .env no VPS (tenant hubsaas, URLs cytoplasm, VITE_API_URL=/v1/), aplicar via apply-vps-env.sh, atualizar backup e validar login — sem modificar código hubsaas."
todos:
  - id: update-env-files
    content: "Atualizar env-servidor/ + hubsaas local: tenant hubsaas, URLs cytoplasm, /v1/ no frontend VPS"
    status: completed
  - id: apply-vps
    content: apply-vps-env.sh no VPS + backup ~/.hubsaas-backup + restart
    status: completed
  - id: validate-login
    content: test-vite-proxy.py + browser nsys/ngrok com platform@hubsaas.local
    status: completed
  - id: harden-update
    content: configure-hubsaas-env.sh cytoplasm + aviso demo-alpha no update.sh
    status: completed
isProject: true
---

# Corrigir login VPS via .env

Plano implementado. Ver documentação viva:

- [README.md](../../README.md) — mapa de pastas
- [docs/deploy/hubsaas-vps-login.md](../../docs/deploy/hubsaas-vps-login.md) — diagnóstico completo
- [scripts/deploy/apply-vps-env.sh](../../scripts/deploy/apply-vps-env.sh) — aplicar templates
- [.cursor/skills/hubsaas-vps-deploy/SKILL.md](../skills/hubsaas-vps-deploy/SKILL.md) — skill do agente

## Pastas relacionadas

| Feature | Pasta |
|---------|-------|
| Deploy | `scripts/deploy/` |
| .env | `scripts/env/`, `env-servidor/` |
| Login / testes | `scripts/login/` |
| Ngrok | `scripts/ngrok/`, `systemd/` |
| Nginx | `scripts/nginx/` |
| PostgreSQL | `scripts/postgres/` |
| Patches hubsaas | `scripts/patches/` |
| Entrada | `debian` (CLI na raiz) + `scripts/<feature>/` |

## Valores alvo (VPS)

**Backend:** `FRONTEND_URL=https://cytoplasm-quicken-asparagus.ngrok-free.dev`, `AUTH_BOOTSTRAP_ENABLED=false`

**Frontend:** `VITE_API_URL=/v1/`, `VITE_DEFAULT_TENANT_SLUG=hubsaas`

**Login:** `platform@hubsaas.local` / `demo1234` (não `.com`)

## O que não resolve só com .env

- Header `ngrok-skip-browser-warning` no frontend (PR hubsaas)
- Tenant fallback no código (PR hubsaas)
