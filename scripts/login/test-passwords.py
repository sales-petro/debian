#!/usr/bin/env python3
import json
import urllib.error
import urllib.request

def test(email, password, base="https://cytoplasm-quicken-asparagus.ngrok-free.dev/v1"):
    payload = json.dumps({"email": email, "password": password}).encode()
    req = urllib.request.Request(
        f"{base}/auth/login-context",
        data=payload,
        headers={"Content-Type": "application/json", "ngrok-skip-browser-warning": "true"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            print(f"OK {password!r} -> {resp.status}")
    except urllib.error.HTTPError as exc:
        print(f"ERR {password!r} -> {exc.code}: {exc.read().decode()[:120]}")

test("platform@hubsaas.local", "demo1234")
test("platform@hubsaas.local", "wrongpass")
test("platform@hubsaas.local", "admin123")
