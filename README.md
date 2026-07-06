# Repo debian — scripts de infra HubSaaS

Scripts de deploy, configuração e diagnóstico para o HubSaaS no VPS Debian (`192.168.100.220`).

| Onde | Caminho |
|------|---------|
| App (git) | `~/hubsaas` |
| Scripts (este repo) | `~/debian` |
| Backup `.env` | `~/.hubsaas-backup/` |

## Estrutura (só pastas na raiz)

```
debian/
├── debian                  # CLI unificada (bash debian help)
├── README.md
├── .cursor/                # plans + skills Cursor
├── docs/                   # documentação
├── env-servidor/           # .env reais gitignored; .env.example versionado
├── scripts/                # implementação por feature
│   ├── deploy/
│   ├── env/
│   ├── login/
│   ├── nginx/
│   ├── ngrok/
│   ├── patches/
│   ├── postgres/
│   └── lib/
└── systemd/
```

## Comandos frequentes (VPS)

```bash
# Deploy
bash ~/debian/scripts/deploy/update.sh
bash ~/debian/debian update

# Aplicar .env do env-servidor + backup
bash ~/debian/scripts/deploy/apply-vps-env.sh

# Testar login
python3 ~/debian/scripts/login/test-vite-proxy.py
bash ~/debian/debian test-vite-proxy

# No-IP / DDNS hubswp.ddns.net
bash ~/debian/debian install-noip-ddclient hubswp.ddns.net
bash ~/debian/debian configure-hubsaas-ddns http://hubswp.ddns.net:3020

# PostgreSQL remoto
bash ~/debian/scripts/postgres/setup-postgres-remote.sh
```

## Onde está cada script que era da raiz

| Feature | Pasta | Scripts |
|---------|-------|---------|
| Deploy | `scripts/deploy/` | `update.sh`, `apply-vps-env.sh`, `run-update.sh` |
| Env | `scripts/env/` | `configure-hubsaas-env.sh`, `configure-hubsaas-ddns.sh`, `install-noip-ddclient.sh`, `apply-backend-env-ngrok.sh` |
| Ngrok | `scripts/ngrok/` | `install-ngrok-dual.sh`, `ngrok-port.sh`, `enable-ngrok-boot.sh`, … |
| Nginx | `scripts/nginx/` | `install-nginx.sh`, `setup-nginx-stack.sh`, `activate-ngrok-nginx.sh` |
| Postgres | `scripts/postgres/` | `setup-postgres-remote.sh`, `diag-postgres.sh` |
| Login | `scripts/login/` | `test-vite-proxy.py`, `test-tenant-slug.py`, … |

Cada pasta tem `README.md` com detalhes.

## Credenciais login

| Campo | Valor |
|-------|--------|
| E-mail | `platform@hubsaas.local` |
| Senha | `demo1234` |
| Tenant | `hubsaas` |

## Documentação

- [docs/deploy/hubsaas-vps-login.md](docs/deploy/hubsaas-vps-login.md)
- [docs/system/create-admin-user.md](docs/system/create-admin-user.md)
- [.cursor/skills/hubsaas-vps-deploy/SKILL.md](.cursor/skills/hubsaas-vps-deploy/SKILL.md)

## O que não vai para o git

Ver [.gitignore](.gitignore): `env-servidor/**/.env`, segredos, logs, tokens ngrok.
