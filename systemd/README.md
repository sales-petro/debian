# Systemd (`systemd/`)

Units para ngrok em **user systemd** (`~/.config/systemd/user/`).

| Unit | Túnel |
|------|-------|
| `hubsaas-backend.service` | :3021 (API) |
| `hubsaas-frontend.service` | :3020 (Vite) |
| `hubsaas-ngrok.service` | :80 via nginx (modo legado) |

Instalação: `bash ~/debian/scripts/ngrok/install-ngrok-dual.sh TOKEN_BACKEND TOKEN_FRONTEND`

Paths nos units apontam para `~/debian/scripts/ngrok/`. Após atualizar este repo no VPS, reinstale os units se os paths mudaram.
