# Ngrok (`scripts/ngrok/`)

| Script | Descrição |
|--------|-----------|
| `install-ngrok.sh TOKEN [porta]` | túnel único via nginx :80 |
| `install-ngrok-dual.sh TOKEN_BE TOKEN_FE` | backend :3021 + frontend :3020 |
| `start-ngrok.sh`, `start-ngrok-tunnel.sh` | usados pelos units systemd |
| `wait-ngrok-port.sh`, `ngrok-port.sh`, `ngrok-status.sh` | utilitários |
| `enable-ngrok-boot.sh` | linger no boot |
| `install-ngrok-windows.ps1` | dev local Windows |

Units: [systemd/](../../systemd/) — após mover scripts, reinstale com `install-ngrok-dual.sh`.

Túneis atuais:
- **prepaid** → :3021 (API)
- **cytoplasm** → :3020 (frontend)
