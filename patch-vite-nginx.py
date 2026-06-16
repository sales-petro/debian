#!/usr/bin/env python3
"""Ajusta vite.config.ts para nginx + ngrok (VITE_API_URL=/v1/)."""
from pathlib import Path

path = Path.home() / "hubsaas/apps/frontend/vite.config.ts"
content = path.read_text(encoding="utf-8")

old_api = """  const apiUrl = env.VITE_API_URL ?? env.REACT_APP_API_URL ?? 'http://localhost:3021/v1/';
  const apiOrigin = new URL(apiUrl);"""

new_api = """  const apiUrl = env.VITE_API_URL ?? env.REACT_APP_API_URL ?? 'http://localhost:3021/v1/';
  const proxyTarget = apiUrl.startsWith('/')
    ? 'http://127.0.0.1:3021'
    : new URL(apiUrl).origin;"""

if old_api not in content:
    if new_api.split("\n")[1].strip() in content:
        print("vite.config.ts já patchado")
    else:
        raise SystemExit("PATCH MISS: bloco apiUrl não encontrado")
else:
    content = content.replace(old_api, new_api, 1)

old_proxy = "          target: apiOrigin.origin,"
new_proxy = "          target: proxyTarget,"

if old_proxy in content:
    content = content.replace(old_proxy, new_proxy, 1)

old_hosts = "      allowedHosts: ['nsys.ddns.net'],"
new_hosts = """      allowedHosts: [
        'nsys.ddns.net',
        'prepaid-untying-capsule.ngrok-free.dev',
        '.ngrok-free.dev',
        'localhost',
      ],"""

if old_hosts in content:
    content = content.replace(old_hosts, new_hosts, 1)
elif ".ngrok-free.dev" not in content:
    content = content.replace(
        "      strictPort: true,",
        """      strictPort: true,
      allowedHosts: [
        'prepaid-untying-capsule.ngrok-free.dev',
        '.ngrok-free.dev',
        'localhost',
      ],""",
        1,
    )

path.write_text(content, encoding="utf-8")
print("vite.config.ts atualizado para nginx/ngrok")
