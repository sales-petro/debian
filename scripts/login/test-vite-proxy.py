#!/usr/bin/env python3
import json
import urllib.error
import urllib.request

def test(base, label):
    body = json.dumps({"email": "platform@hubsaas.local", "password": "demo1234"}).encode()
    headers = {"Content-Type": "application/json"}
    if "ngrok" in base:
        headers["ngrok-skip-browser-warning"] = "true"
    # login-context
    req = urllib.request.Request(
        f"{base}/auth/login-context",
        data=body,
        headers=headers,
    )
    try:
        with urllib.request.urlopen(req) as r:
            ctx = json.loads(r.read().decode())
            print(f"{label} login-context: OK")
    except urllib.error.HTTPError as e:
        print(f"{label} login-context: ERR {e.code} {e.read().decode()[:100]}")
        return

    tenant = ctx["tenants"][0]
    req2 = urllib.request.Request(
        f"{base}/auth/login",
        data=body,
        headers={**headers, "X-Tenant-Slug": tenant["tenantSlug"]},
    )
    try:
        with urllib.request.urlopen(req2) as r:
            login = json.loads(r.read().decode())
            print(f"{label} login: OK token={login.get('accessToken','')[:20]}...")
    except urllib.error.HTTPError as e:
        print(f"{label} login: ERR {e.code} {e.read().decode()[:150]}")

test("http://127.0.0.1:3020/v1", "vite-proxy")
test("http://127.0.0.1:3021/v1", "backend-direct")
test("https://cytoplasm-quicken-asparagus.ngrok-free.dev/v1", "ngrok-frontend")
