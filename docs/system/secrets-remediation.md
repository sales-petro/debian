# Remediação de segredos expostos

Se o GitGuardian (ou similar) detectou vazamento neste repositório:

## 1. Rotacionar credenciais

| Tipo | Ação |
|------|------|
| Tokens ngrok | [Dashboard ngrok](https://dashboard.ngrok.com/) → revogar e criar novos authtokens |
| Postgres | Alterar senha do usuário `postgres` no VPS |
| JWT / fiscal | Gerar novos valores em `env-servidor/apps/backend/.env` e reiniciar backend |

## 2. Estrutura atual (após correção)

- **`env-servidor/`** — gitignored; `.env` reais com segredos
- **`env-servidor.example/`** — templates versionados **sem** senhas nem tokens
- Tokens ngrok só via argumentos ou `NGROK_BACKEND_TOKEN` / `NGROK_FRONTEND_TOKEN`

## 3. Setup local

```bash
cp -r env-servidor.example env-servidor
cp env-servidor.example/apps/backend/.env.example env-servidor/apps/backend/.env
cp env-servidor.example/apps/frontend/.env.example env-servidor/apps/frontend/.env
# Edite env-servidor/apps/*/.env
```

## 4. Histórico do git

Arquivos removidos do tracking ainda podem existir em commits antigos. Para limpar o histórico remoto:

```bash
# Exemplo com git-filter-repo (instalar separadamente)
git filter-repo --path env-servidor/apps/backend/.env.example --invert-paths
git filter-repo --path scripts/ngrok/install-ngrok-dual.sh --replace-text expressions.txt
```

Ou use a [guia do GitGuardian](https://docs.gitguardian.com/secrets-detection/secrets-remediation/overview) e **force push** apenas se o time concordar.

Depois de rotacionar segredos, marque o incidente como resolvido no GitGuardian.
