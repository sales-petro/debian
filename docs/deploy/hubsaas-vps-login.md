# HubSaaS — login no VPS Debian (hubswp.ddns.net)

Documento para o time de **backend/frontend** corrigir no repositório `hubsaas`, publicar no git e atualizar o servidor.

**Data do diagnóstico:** 2026-06-17  
**URL pública:** http://hubswp.ddns.net:3020/login  
**Servidor:** Debian `192.168.100.220` (usuário `celio`, app em `~/hubsaas`)

---

## Resumo executivo

| Item | Status |
|------|--------|
| Backend porta 3021 | **OK** (`curl http://127.0.0.1:3021/v1/health` → 200) |
| Frontend porta 3020 | **OK** |
| PostgreSQL `hubsaas` | **OK** (usuário `platform@hubsaas.local` existe) |
| API login com senha correta | **OK** no servidor |
| Login pela tela do browser | **FALHA** — configuração de tenant no frontend |

**Conclusão:** o backend está no ar. O login falha na UI porque o frontend envia um **tenant slug errado** (`demo-alpha`), que não existe no banco restaurado. A API responde `401 Invalid credentials` mesmo com e-mail e senha corretos.

---

## Causa raiz

### 1. `VITE_DEFAULT_TENANT_SLUG` desatualizado

No servidor (`~/hubsaas/apps/frontend/.env`):

```env
VITE_DEFAULT_TENANT_SLUG=demo-alpha
```

No banco restaurado, o usuário `platform@hubsaas.local` pertence aos tenants:

| slug | nome |
|------|------|
| `hubsaas` | HubSaaS |
| `shopee-review` | MilMay Quazany |

**Não existe** `demo-alpha`.

Teste feito no VPS:

```text
X-Tenant-Slug: demo-alpha  → 401 Invalid credentials
X-Tenant-Slug: hubsaas     → 200 OK + accessToken
```

O frontend usa `VITE_DEFAULT_TENANT_SLUG` no header `X-Tenant-Slug` no `POST /v1/auth/login`. Tenant inválido gera o mesmo erro genérico de senha errada.

### 2. `FRONTEND_URL` apontando para ngrok

Backend `.env` no servidor:

```env
FRONTEND_URL=https://prepaid-untying-capsule.ngrok-free.dev
```

Para deploy em `http://hubswp.ddns.net:3020`, isso deve ser a URL pública real (CORS, links, redirects).

### 3. Restore do banco não é o problema do login

Após restore, o usuário e os tenants existem. A API autentica com `demo1234` quando o tenant slug está correto.

---

## Correção imediata no VPS (sem mudar código)

No SSH do Debian:

```bash
cd ~/debian
bash debian configure-hubsaas-ddns http://hubswp.ddns.net:3020
```

Ou manualmente em `apps/frontend/.env`:

```env
VITE_DEFAULT_TENANT_SLUG=hubsaas
```

E em `apps/backend/.env`:

```env
FRONTEND_URL=http://hubswp.ddns.net:3020
```

Reiniciar (variáveis `VITE_*` só aplicam após reinício do Vite):

```bash
sudo systemctl restart hubsaas
# ou, se rodando manualmente:
pkill -f 'vite|main.js' ; cd ~/hubsaas && ./run-update.sh
```

**Credenciais de teste** (banco restaurado do local):

- E-mail: `platform@hubsaas.local`
- Senha: `demo1234`
- Tenant: `hubsaas` (não `demo-alpha`)

---

## Correções recomendadas no repositório `hubsaas` (git)

Estas mudanças evitam que o problema volte após `git pull` + restore de `.env` antigo.

### Frontend — não depender de tenant fixo no `.env`

**Problema:** `VITE_DEFAULT_TENANT_SLUG` hardcoded quebra quando o banco muda.

**Sugestão:**

1. No fluxo de login, chamar `POST /auth/login-context` primeiro.
2. Usar o `tenantSlug` retornado (ou o escolhido pelo usuário na UI) no `POST /auth/login`.
3. Tratar `401` com tenant inválido com mensagem distinta: *"Tenant não encontrado ou sem acesso"* vs *"Senha incorreta"*.
4. Remover `demo-alpha` dos exemplos de `.env.example`; usar `hubsaas` ou deixar vazio para forçar seleção.

Arquivos prováveis: serviço/hook de auth no frontend (`login`, `authApi`, store).

### Frontend — `vite.config.ts` para proxy `/v1/`

Quando `VITE_API_URL=/v1/`, o proxy do Vite deve apontar para `http://127.0.0.1:3021` (não fazer parse de URL relativa com `new URL()`).

Patch de referência: `scripts/patches/patch-vite-nginx.py`.

Incluir em `allowedHosts`:

```ts
allowedHosts: ['hubswp.ddns.net', 'localhost', '.ngrok-free.dev']
```

### Backend — refresh token com `jti` único

Sessões duplicadas / refresh inválido após restore podem exigir `jti` no JWT de refresh.

Patch de referência: `scripts/patches/patch-auth-jti.py` → incorporar em `apps/backend/src/modules/auth/auth.service.ts`:

```ts
import { randomUUID } from 'node:crypto';

const refreshToken = this.jwtService.sign(
  { ...payload, jti: randomUUID() },
  { secret: this.auth.refreshSecret, expiresIn: ... },
);
```

### Backend — CORS / `FRONTEND_URL`

Garantir que `FRONTEND_URL` (e lista de origens, se houver) aceite:

- `http://hubswp.ddns.net:3020`
- URL ngrok quando usada
- `http://localhost:3020` em dev

Documentar no `.env.example` do backend.

### Seeds / migrations

Se o seed cria tenant `demo-alpha` mas o dump de produção usa `hubsaas`, alinhar:

- slug padrão do seed = `hubsaas`, **ou**
- documentar que restore substitui seeds e o `.env` do frontend deve seguir o banco.

---

## Arquivos de ambiente de referência (deploy)

### `apps/backend/.env` (VPS — portas diretas)

```env
PORT=3021
DATABASE_HOST=127.0.0.1
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
# Senha: definir DATABASE_PASSWORD no .env real (env-servidor/, gitignored)
DATABASE_NAME=hubsaas
REDIS_URL=redis://127.0.0.1:6379
FRONTEND_URL=http://hubswp.ddns.net:3020
AUTH_BOOTSTRAP_ENABLED=false
```

### `apps/frontend/.env` (VPS)

```env
PORT=3020
VITE_API_URL=/v1/
VITE_DEFAULT_TENANT_SLUG=hubsaas
```

> Após restore do banco, conferir no Postgres qual slug o usuário tem:
>
> ```sql
> SELECT t.slug FROM users_tenant_memberships utm
> JOIN tenants t ON t.id = utm.tenant_id
> JOIN users_accounts ua ON ua.id = utm.account_id
> WHERE ua.email = 'platform@hubsaas.local';
> ```

---

## Fluxo de deploy após correção no git

No VPS (`~/hubsaas` ou via `update.sh` do repo debian):

```bash
cd ~/hubsaas
git pull origin main
pnpm install
pnpm turbo run build
pnpm migration:run
# restaurar .env local (update.sh faz backup automático)
sudo systemctl restart hubsaas
```

Scripts úteis em `scripts/<feature>/`:

| Script | Função |
|--------|--------|
| `scripts/env/configure-hubsaas-ddns.sh` | Ajusta `.env` para hubswp.ddns.net |
| `scripts/env/configure-hubsaas-env.sh` | Ajusta para URL ngrok (cytoplasm) |
| `scripts/deploy/update.sh` | pull + build + migrations + restart |
| `scripts/deploy/apply-vps-env.sh` | Copia `env-servidor/` + backup |
| `scripts/login/test-vite-proxy.py` | Testa login via proxy e backend |
| `scripts/login/test-tenant-slug.py` | Mostra falha com tenant errado |

---

## Testes de validação

### No servidor

```bash
python3 ~/debian/scripts/login/test-vite-proxy.py
```

Esperado:

```text
vite-proxy login-context: OK
vite-proxy login: OK token=eyJ...
backend-direct login-context: OK
backend-direct login: OK token=eyJ...
```

### No browser

1. Abrir http://hubswp.ddns.net:3020/login  
2. F12 → Network → `login-context` e `login`  
3. Verificar header `X-Tenant-Slug: hubsaas` (não `demo-alpha`)  
4. Login com `platform@hubsaas.local` / `demo1234`

### Se ainda falhar

| Sintoma | Verificar |
|---------|-----------|
| `login-context` 401 | Senha no banco vs digitada |
| `login` 401 + slug demo-alpha | `VITE_DEFAULT_TENANT_SLUG` / reinício do Vite |
| Request para host errado | `VITE_API_URL` e proxy do Vite |
| CORS | `FRONTEND_URL` no backend |
| Timeout na API | Portas 3020/3021 e firewall |

---

## Checklist para PR no hubsaas

- [ ] Login usa tenant de `login-context`, não slug fixo obsoleto
- [ ] `.env.example` frontend: `VITE_DEFAULT_TENANT_SLUG=hubsaas` ou vazio
- [ ] `vite.config.ts`: proxy para `/v1/` + `allowedHosts` com `hubswp.ddns.net`
- [ ] `auth.service.ts`: `jti` no refresh token
- [ ] Mensagem de erro diferenciada (tenant vs senha)
- [ ] Documentação de deploy VPS (este arquivo ou README)

---

## Contato / contexto infra

- Postgres 17 (`pg_lsclusters` — cluster 15 está down, ignorar config em `/etc/postgresql/15/`)
- Acesso remoto pgAdmin: `scripts/postgres/setup-postgres-remote.sh` (porta 5432)
- App exposto direto nas portas 3020/3021 (sem nginx no cenário atual)
