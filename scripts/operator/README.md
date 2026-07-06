# Operador HubSaaS (`scripts/operator/`)

Permite que usuários delegados (ex.: **igor**) parem, iniciem e atualizem o HubSaaS **no ambiente do celio**, sem subir uma segunda cópia nas portas 3020/3021.

## Modelo

| Papel | Usuário | O que possui |
|-------|---------|--------------|
| Operador | `celio` | `~/hubsaas`, ngrok (`systemctl --user`), processos nas portas 3020/3021 |
| Delegado | `igor` | `sudo` para rodar `hubsaas-op.sh` **como celio** |

## Instalação (uma vez no VPS)

Como root ou com sudo no servidor:

```bash
# Atualizar repo no celio
sudo -u celio bash -c 'cd ~/debian && git pull'

# Instalar regras sudo para o igor
sudo bash /home/celio/debian/scripts/operator/install-operator-sudoers.sh igor
```

## Comandos (igor ou celio)

```bash
bash ~/debian/scripts/operator/hubsaas-op.sh status
bash ~/debian/scripts/operator/hubsaas-op.sh update
bash ~/debian/scripts/operator/hubsaas-op.sh restart
bash ~/debian/scripts/operator/hubsaas-op.sh stop
bash ~/debian/scripts/operator/hubsaas-op.sh restart-ngrok
```

Ou via CLI:

```bash
bash ~/debian/debian hubsaas-op status
bash ~/debian/debian hubsaas-op update
```

O **igor** pode clonar `~/debian` no próprio home; o script sempre delega para `/home/celio/debian/scripts/operator/hubsaas-op.sh`.

## O que cada comando faz

| Comando | Ação |
|---------|------|
| `update` | `update.sh` completo (git pull, build, migrations, restart) |
| `apply-env` | `apply-vps-env.sh` no `~/hubsaas` do celio |
| `stop` | Para systemd `hubsaas` + processos backend/frontend do celio |
| `start` | Sobe backend + frontend (sem git pull) |
| `restart` | `stop` + `start` + reinicia ngrok do celio |
| `restart-app` | Só app, sem ngrok |
| `restart-ngrok` | `systemctl --user restart hubsaas-backend hubsaas-frontend` |
| `restart-systemd` | `sudo systemctl restart hubsaas` |
| `status` | Portas, health e ngrok |

## Variáveis

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `HUBSAAS_OPERATOR_USER` | `celio` | Dono do stack |

## Documentação

- [docs/system/hubsaas-operator.md](../../docs/system/hubsaas-operator.md)
