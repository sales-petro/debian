#!/usr/bin/env python3
import json
import urllib.error
import urllib.request

body = {"email": "platform@hubsaas.local", "password": "demo1234"}
base = "http://127.0.0.1:3021/v1"

for slug in ["demo-alpha", "hubsaas", "shopee-review", ""]:
    headers = {"Content-Type": "application/json"}
    if slug:
        headers["X-Tenant-Slug"] = slug
    req = urllib.request.Request(
        f"{base}/auth/login",
        data=json.dumps(body).encode(),
        headers=headers,
    )
    try:
        with urllib.request.urlopen(req) as r:
            print(f"slug={slug!r} -> {r.status} OK")
    except urllib.error.HTTPError as e:
        print(f"slug={slug!r} -> {e.code} {e.read().decode()[:200]}")
