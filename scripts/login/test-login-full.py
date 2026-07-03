#!/usr/bin/env python3
import json
import urllib.error
import urllib.request

BASE = "https://cytoplasm-quicken-asparagus.ngrok-free.dev/v1"
HEADERS = {"Content-Type": "application/json", "ngrok-skip-browser-warning": "true"}

def post(path, data):
    payload = json.dumps(data).encode()
    req = urllib.request.Request(
        f"{BASE}{path}",
        data=payload,
        headers=HEADERS,
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        return exc.code, json.loads(exc.read().decode())

status, ctx = post("/auth/login-context", {
    "email": "platform@hubsaas.local",
    "password": "demo1234",
})
print("login-context:", status)
if status != 200:
    print(ctx)
    raise SystemExit(1)

tenant = ctx["tenants"][0]
company = tenant["companies"][0]
print("tenant:", tenant["tenantSlug"], "company:", company.get("name", company["id"]))

status, login = post("/auth/login", {
    "email": "platform@hubsaas.local",
    "password": "demo1234",
    "tenantId": tenant["tenantId"],
    "companyId": company["id"],
})
print("login:", status)
print(json.dumps(login, indent=2)[:400] if isinstance(login, dict) else login)
