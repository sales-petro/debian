#!/usr/bin/env python3
import json
from pathlib import Path

p = Path.home() / "hubsaas/apps/backend/package.json"
data = json.loads(p.read_text(encoding="utf-8"))
data["scripts"]["start"] = (
    "NODE_PATH=./node_modules:../../node_modules node ../../.build/apps/backend/main.js"
)
p.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
print("start script updated")
