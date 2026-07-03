#!/usr/bin/env python3
import json
import urllib.error
import urllib.request

BASE = "https://cytoplasm-quicken-asparagus.ngrok-free.dev/v1"
HEADERS = {"Content-Type": "application/json", "ngrok-skip-browser-warning": "true"}

def post(path, data, extra=None):
    h = {**HEADERS, **(extra or {})}
    req = urllib.request.Request(f"{BASE}{path}", data=json.dumps(data).encode(), headers=h)
    with urllib.request.urlopen(req) as r:
        return r.status, json.loads(r.read().decode())

status, ctx = post("/auth/login-context", {"email": "platform@hubsaas.local", "password": "demo1234"})
print("login-context:", status, "tenants:", len(ctx["tenants"]))
tenant = ctx["tenants"][0]
status, login = post(
    "/auth/login",
    {"email": "platform@hubsaas.local", "password": "demo1234"},
    {"X-Tenant-Slug": tenant["tenantSlug"]},
)
print("login:", status, "token:", login.get("accessToken", "")[:30] + "...")
