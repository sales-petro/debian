# HubSaaS — operador e delegados no VPS

No Debian `192.168.100.220`, o HubSaaS roda **uma única instância** no usuário **celio**. Outros administradores (ex.: **igor**) operam o mesmo stack via `sudo`, sem duplicar processos nas portas 3020/3021.

## Papéis

| Papel | Usuário | Responsabilidade |
|-------|---------|------------------|
| Operador | `celio` | `~/hubsaas`, `~/debian`, ngrok (`systemctl --user`), backend :3021, frontend :3020 |
| Delegado | `igor` | Deploy, restart, status via `hubsaas-op.sh` (executado como celio) |

## Instalação

### 1. Garantir sudo no igor

Ver [create-admin-user.md](create-admin-user.md) ou:

```bash
sudo usermod -aG sudo igor
```

### 2. Atualizar repo no celio

```bash
sudo -u celio bash -c 'cd ~/debian && git pull'
```

### 3. Instalar sudoers (NOPASSWD para hubsaas-op)

```bash
sudo bash /home/celio/debian/scripts/operator/install-operator-sudoers.sh igor
```

Isso cria `/etc/sudoers.d/hubsaas-operator` permitindo:

- `igor` rodar `hubsaas-op.sh` como **celio** (sem senha)
- `igor` controlar o unit de sistema `hubsaas` (`systemctl restart`, etc.)

### 4. Ngrok permanece só no celio

Não instale ngrok no igor. Os túneis continuam no `systemctl --user` do celio. O comando `restart-ngrok` reinicia os units do celio com `XDG_RUNTIME_DIR` correto.

## Uso diário (igor)

```bash
# Status (portas, health, ngrok)
bash ~/debian/debian hubsaas-op status

# Deploy completo
bash ~/debian/debian hubsaas-op update

# Reiniciar app + ngrok
bash ~/debian/debian hubsaas-op restart

# Só parar (manutenção)
bash ~/debian/debian hubsaas-op stop

# Só subir de novo
bash ~/debian/debian hubsaas-op start

# Só ngrok
bash ~/debian/debian hubsaas-op restart-ngrok
```

Equivalente manual (sem o script):

```bash
sudo -u celio bash /home/celio/debian/scripts/deploy/update.sh
sudo -u celio bash -c 'export XDG_RUNTIME_DIR=/run/user/$(id -u celio); systemctl --user restart hubsaas-backend hubsaas-frontend'
```

## Verificação

Como **igor**:

```bash
bash /home/celio/debian/scripts/operator/hubsaas-op.sh status
sudo -u celio whoami   # deve imprimir: celio
```

Confirme que não há processos duplicados:

```bash
ss -tlnp | grep -E '3020|3021'
ps aux | grep -E 'main.js|vite' | grep -v grep
```

Deve haver **um** backend e **um** frontend, dono `celio`.

## O que o igor não deve fazer

- Rodar `pnpm dev` ou `update.sh` diretamente no próprio `~/hubsaas` (conflita nas portas)
- Instalar `install-ngrok-dual.sh` como igor
- Habilitar `loginctl enable-linger igor` para ngrok (desnecessário neste modelo)

## Referências

- [scripts/operator/README.md](../../scripts/operator/README.md)
- [README.md](../../README.md) — comandos frequentes no VPS
