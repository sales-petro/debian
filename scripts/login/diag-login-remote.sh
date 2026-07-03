#!/bin/bash
set -euo pipefail
export PGPASSWORD="${PGPASSWORD:-postgres}"

echo "== ENV backend (sem secrets) =="
grep -E '^(PORT|FRONTEND_URL|DATABASE_|REDIS_|AUTH_)' ~/hubsaas/apps/backend/.env 2>/dev/null | grep -v SECRET | grep -v PASSWORD || true

echo ""
echo "== ENV frontend =="
cat ~/hubsaas/apps/frontend/.env 2>/dev/null || true

echo ""
echo "== Usuário platform =="
psql -h 127.0.0.1 -U postgres -d hubsaas -c "SELECT email, status, left(password_hash,20) as hash FROM users_accounts WHERE email='platform@hubsaas.local';"

echo ""
echo "== Tenants do usuário =="
psql -h 127.0.0.1 -U postgres -d hubsaas -c "SELECT t.slug, t.name, utm.status FROM users_tenant_memberships utm JOIN tenants t ON t.id=utm.tenant_id JOIN users_accounts ua ON ua.id=utm.account_id WHERE ua.email='platform@hubsaas.local';"

echo ""
echo "== Teste API direto (backend 3021) =="
python3 <<'PY'
import json, urllib.error, urllib.request

def post(path, body, headers=None):
    h = {"Content-Type": "application/json", **(headers or {})}
    req = urllib.request.Request(f"http://127.0.0.1:3021/v1{path}", data=json.dumps(body).encode(), headers=h)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()

for pwd in ["demo1234", "admin123", "postgres"]:
    s, ctx = post("/auth/login-context", {"email": "platform@hubsaas.local", "password": pwd})
    print(f"password={pwd!r} login-context -> {s}", end="")
    if isinstance(ctx, dict) and ctx.get("tenants"):
        print(f" tenants={len(ctx['tenants'])} slug={ctx['tenants'][0].get('tenantSlug')}")
        slug = ctx["tenants"][0]["tenantSlug"]
        s2, login = post("/auth/login", {"email": "platform@hubsaas.local", "password": pwd}, {"X-Tenant-Slug": slug})
        print(f"  login -> {s2}", str(login)[:120])
    else:
        print(f" body={str(ctx)[:120]}")

print()
print("== Teste via Vite proxy (3020) =="
)
s, ctx = post_via := None
import urllib.request, json
body = json.dumps({"email": "platform@hubsaas.local", "password": "demo1234"}).encode()
req = urllib.request.Request("http://127.0.0.1:3020/v1/auth/login-context", data=body, headers={"Content-Type": "application/json"})
try:
    with urllib.request.urlopen(req) as r:
        print("vite-proxy login-context:", r.status)
except urllib.error.HTTPError as e:
    print("vite-proxy login-context:", e.code, e.read().decode()[:200])
PY
