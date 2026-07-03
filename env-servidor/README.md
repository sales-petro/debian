# Templates .env do VPS

Esta pasta é **gitignored** exceto os `.env.example`.

Copie os exemplos para `.env` localmente, preencha segredos e use:

```bash
bash scripts/deploy/apply-vps-env.sh   # no VPS
```

| Arquivo | Destino no VPS |
|---------|----------------|
| `apps/backend/.env.example` | `~/hubsaas/apps/backend/.env` |
| `apps/frontend/.env.example` | `~/hubsaas/apps/frontend/.env` |
