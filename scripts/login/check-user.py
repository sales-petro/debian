#!/usr/bin/env python3
import subprocess

EMAIL = "platform@hubsaas.local"
env = {"PGPASSWORD": "postgres"}

def psql(sql):
    r = subprocess.run(
        ["psql", "-h", "127.0.0.1", "-U", "postgres", "-d", "hubsaas", "-c", sql],
        capture_output=True,
        text=True,
        env={**subprocess.os.environ, **env},
    )
    return r.stdout + r.stderr

print("=== users_accounts ===")
print(psql(f"SELECT id, email, status, name, created_at FROM users_accounts WHERE email = '{EMAIL}';"))

print("=== users (tenant) ===")
print(psql(f"""
SELECT u.id, u.email, u.status, t.slug AS tenant_slug, t.name AS tenant_name
FROM users u
JOIN tenants t ON t.id = u.tenant_id
WHERE u.email = '{EMAIL}';
"""))

print("=== memberships ===")
print(psql(f"""
SELECT m.status, t.slug, t.name
FROM users_tenant_memberships m
JOIN users_accounts a ON a.id = m.account_id
JOIN tenants t ON t.id = m.tenant_id
WHERE a.email = '{EMAIL}';
"""))

print("=== platform roles ===")
print(psql(f"""
SELECT sr.slug, sr.name
FROM users_accounts a
JOIN users_platform_roles upr ON upr.account_id = a.id
JOIN users_system_roles sr ON sr.id = upr.system_role_id
WHERE a.email = '{EMAIL}';
"""))
