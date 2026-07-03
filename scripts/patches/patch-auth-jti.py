#!/usr/bin/env python3
from pathlib import Path

path = Path.home() / "hubsaas/apps/backend/src/modules/auth/auth.service.ts"
content = path.read_text(encoding="utf-8")

old_import = "import { ForbiddenException, Injectable, UnauthorizedException } from '@nestjs/common';"
new_import = "import { randomUUID } from 'node:crypto';\nimport { ForbiddenException, Injectable, UnauthorizedException } from '@nestjs/common';"

old_sign = """    const refreshToken = this.jwtService.sign(payload, {
      secret: this.auth.refreshSecret,
      expiresIn: this.auth.refreshExpiresIn as `${number}${'s' | 'm' | 'h' | 'd'}`,
    });"""

new_sign = """    const refreshToken = this.jwtService.sign(
      { ...payload, jti: randomUUID() },
      {
        secret: this.auth.refreshSecret,
        expiresIn: this.auth.refreshExpiresIn as `${number}${'s' | 'm' | 'h' | 'd'}`,
      },
    );"""

if old_import not in content:
    raise SystemExit("import patch miss")
if "jti: randomUUID()" in content:
    print("already patched")
else:
    content = content.replace(old_import, new_import, 1)
    content = content.replace(old_sign, new_sign, 1)
    path.write_text(content, encoding="utf-8")
    print("patched auth.service.ts")
