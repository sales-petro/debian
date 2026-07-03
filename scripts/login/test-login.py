#!/usr/bin/env python3
import json
import urllib.error
import urllib.request

payload = json.dumps({"email": "platform@hubsaas.local", "password": "demo1234"}).encode()
urls = [
    "http://127.0.0.1:3021/v1/auth/login-context",
    "https://cytoplasm-quicken-asparagus.ngrok-free.dev/v1/auth/login-context",
]

for url in urls:
    req = urllib.request.Request(
        url,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "ngrok-skip-browser-warning": "true",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            body = resp.read().decode()
            print(f"OK {url} -> {resp.status}")
            print(body[:300])
    except urllib.error.HTTPError as exc:
        body = exc.read().decode()
        print(f"ERR {url} -> {exc.code}")
        print(body[:300])
    print("---")
