#!/usr/bin/env python3
import json
import urllib.error
import urllib.request

BASE = "https://cytoplasm-quicken-asparagus.ngrok-free.dev/v1/auth/login-context"
body = json.dumps({"email": "platform@hubsaas.local", "password": "demo1234"}).encode()

for label, headers in [
    ("sem header ngrok", {"Content-Type": "application/json"}),
    ("com ngrok-skip-browser-warning", {"Content-Type": "application/json", "ngrok-skip-browser-warning": "true"}),
]:
    req = urllib.request.Request(BASE, data=body, headers=headers)
    try:
        with urllib.request.urlopen(req) as r:
            text = r.read().decode()
            print(f"{label}: HTTP {r.status} | starts with: {text[:80]!r}")
    except urllib.error.HTTPError as e:
        text = e.read().decode()
        print(f"{label}: HTTP {e.code} | starts with: {text[:120]!r}")
