#!/usr/bin/env python3
import os
import subprocess

pgpass = os.environ.get("PGPASSWORD")
if not pgpass:
    raise SystemExit("Defina PGPASSWORD (senha do Postgres) antes de rodar este script.")

subprocess.run([
    "psql", "-h", "127.0.0.1", "-U", "postgres", "-d", "hubsaas",
    "-c", "SELECT id, user_id, left(token_hash,16) as hash, expires_at, revoked_at FROM auth_refresh_tokens WHERE user_id='bf65caa6-fe1c-4cb3-8221-c2bde11ed737' ORDER BY created_at DESC LIMIT 5;"
], env={**os.environ, "PGPASSWORD": pgpass})
