# Nginx (`scripts/nginx/`)

Reverse proxy `:80` → frontend `:3020`, `/v1/` → backend `:3021`.

| Script | Descrição |
|--------|-----------|
| `install-nginx.sh` | `sudo` — instala `hubsaas.conf` |
| `setup-nginx-stack.sh` | env + patch vite + nginx + ngrok |
| `activate-ngrok-nginx.sh` | ngrok passa de :3020 para :80 |
| `hubsaas.conf` | config nginx |

Doc: [docs/deploy/hubsaas-vps-login.md](../../docs/deploy/hubsaas-vps-login.md)
