# Env (`scripts/env/`)

Ajusta `.env` em `~/hubsaas/apps/{backend,frontend}/`.

| Script | Uso |
|--------|-----|
| `configure-hubsaas-env.sh [URL]` | ngrok frontend (cytoplasm) + tenant `hubsaas` |
| `configure-hubsaas-ddns.sh [URL]` | No-IP/DDNS, padrao `http://hubswp.ddns.net:3020` |
| `install-noip-ddclient.sh [HOST]` | instala `ddclient` para atualizar `hubswp.ddns.net` no No-IP |
| `apply-backend-env-ngrok.sh [URL]` | só vars fiscais/Shopee no backend |

Templates VPS: `env-servidor.example/` (versionado). Copie para `env-servidor/` (gitignored) e preencha segredos.

## No-IP (`hubswp.ddns.net`)

No painel No-IP, crie uma credencial de DDNS para `hubswp.ddns.net`. Se a conta foi criada com Google (`petrofuelbusiness@gmail.com`), nao use a senha do Google no Debian; use uma **DDNS Key** ou uma senha propria do No-IP.

No Debian:

```bash
cd ~/debian
bash debian install-noip-ddclient hubswp.ddns.net
bash debian configure-hubsaas-ddns http://hubswp.ddns.net:3020
sudo systemctl restart hubsaas
```

Validacao:

```bash
systemctl status ddclient --no-pager
getent ahostsv4 hubswp.ddns.net
python3 ~/debian/scripts/login/test-vite-proxy.py
```
