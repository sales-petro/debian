#!/usr/bin/env python3
import subprocess
import urllib.error
import urllib.request
import json

# Test API login
payload = json.dumps({"email": "platform@hubsaas.local", "password": "demo1234"}).encode()
for url in [
    "http://127.0.0.1:3021/v1/auth/login-context",
    "https://cytoplasm-quicken-asparagus.ngrok-free.dev/v1/auth/login-context",
]:
    req = urllib.request.Request(
        url, data=payload,
        headers={"Content-Type": "application/json", "ngrok-skip-browser-warning": "true"},
    )
    try:
        with urllib.request.urlopen(req) as r:
            print(f"API {url}: OK {r.status}")
    except urllib.error.HTTPError as e:
        print(f"API {url}: ERR {e.code} {e.read().decode()[:100]}")

# Check password via node bcrypt (PGPASSWORD no ambiente)
import os

pgpass = os.environ.get("PGPASSWORD", "")
hubsaas_backend = os.environ.get(
    "HUBSAAS_BACKEND_DIR",
    os.path.expanduser("~/hubsaas/apps/backend"),
)

script = f"""
const bcrypt = require('bcrypt');
const {{ Client }} = require('pg');
(async () => {{
  const c = new Client({{ host: '127.0.0.1', user: 'postgres', password: process.env.PGPASSWORD, database: 'hubsaas' }});
  await c.connect();
  const r = await c.query("SELECT password_hash FROM users_accounts WHERE email='platform@hubsaas.local'");
  if (!r.rows.length) {{ console.log('usuario nao encontrado'); process.exit(1); }}
  for (const pwd of ['demo1234', 'admin123', 'hubsaas', 'password']) {{
    const ok = await bcrypt.compare(pwd, r.rows[0].password_hash);
    console.log('senha', pwd + ':', ok ? 'CORRETA' : 'incorreta');
  }}
  await c.end();
}})();
"""
r = subprocess.run(
    ["node", "-e", script],
    cwd=hubsaas_backend,
    capture_output=True,
    text=True,
    env={**os.environ, "PGPASSWORD": pgpass},
)
print(r.stdout)
if r.stderr:
    print(r.stderr[:300])
