#!/usr/bin/env python3
"""Aplica correções TypeScript no backend hubsaas."""
from pathlib import Path

BASE = Path.home() / "hubsaas"

def patch_file(rel_path: str, replacements: list[tuple[str, str]]) -> None:
    path = BASE / rel_path
    content = path.read_text(encoding="utf-8")
    original = content
    for old, new in replacements:
        if old not in content:
            raise SystemExit(f"PATCH MISS in {rel_path}: {old[:80]!r}...")
        content = content.replace(old, new, 1)
    if content == original:
        raise SystemExit(f"NO CHANGE in {rel_path}")
    path.write_text(content, encoding="utf-8")
    print(f"OK {rel_path}")

patch_file(
    "apps/backend/src/modules/fiscal/fiscal.controller.ts",
    [
        (
            "body as Parameters<FiscalInvoiceService['emit']>[2],",
            "body as Parameters<FiscalInvoiceService['emit']>[3],",
        ),
    ],
)

patch_file(
    "apps/backend/src/modules/user/user.service.ts",
    [
        (
            """    await this.membershipRepository.create({
      accountId: account.id,
      tenantId,
      userId: user.id,
      status,
    });""",
            """    await this.membershipRepository.create({
      accountId: account.id,
      tenantId,
      userId: user.id,
      status: status === 'invited' ? 'active' : status,
    });""",
        ),
    ],
)

patch_file(
    "apps/backend/src/modules/rbac/rbac.service.ts",
    [
        (
            """    const roleSlug = dto.roleSlugs[0];
    const role = await this.rbacRepository.findSystemRoleBySlug(roleSlug);""",
            """    const roleSlug = dto.roleSlugs[0];
    if (!roleSlug) {
      throw new BadRequestException('roleSlugs must contain at least one role');
    }
    const role = await this.rbacRepository.findSystemRoleBySlug(roleSlug);""",
        ),
        (
            "if (!TENANT_SCOPED_PERMISSION_KEYS.includes(entry.key)) {",
            "if (!(TENANT_SCOPED_PERMISSION_KEYS as readonly string[]).includes(entry.key)) {",
        ),
        (
            """      const [resource, action] = entry.key.split(':');
      const perm = await this.rbacRepository.findPermissionByKey(resource, action);
      if (!perm) {
        throw new BadRequestException(`Unknown permission: ${entry.key}`);
      }""",
            """      const [resource, action] = entry.key.split(':');
      if (!resource || !action) {
        throw new BadRequestException(`Invalid permission key: ${entry.key}`);
      }
      const perm = await this.rbacRepository.findPermissionByKey(resource, action);
      if (!perm) {
        throw new BadRequestException(`Unknown permission: ${entry.key}`);
      }""",
        ),
        (
            "if (!TENANT_SCOPED_PERMISSION_KEYS.includes(key)) {",
            "if (!(TENANT_SCOPED_PERMISSION_KEYS as readonly string[]).includes(key)) {",
        ),
        (
            """      const [resource, action] = key.split(':');
      const perm = await this.rbacRepository.findPermissionByKey(resource, action);
      if (perm) {
        permissionIds.push(perm.id);
      }""",
            """      const [resource, action] = key.split(':');
      if (!resource || !action) {
        throw new BadRequestException(`Invalid permission key: ${key}`);
      }
      const perm = await this.rbacRepository.findPermissionByKey(resource, action);
      if (perm) {
        permissionIds.push(perm.id);
      }""",
        ),
    ],
)

patch_file(
    "apps/backend/src/modules/finance/finance.service.ts",
    [
        (
            """          directAmountCents,
          amountCents,
          children,
        };""",
            """          directAmountCents,
          amountCents,
          children: children ?? [],
        };""",
        ),
        (
            """      report.revenueTree = this.buildDreTree(categories, directAmounts, totals, 'receita');
      report.expenseTree = this.buildDreTree(categories, directAmounts, totals, 'despesa');
      report.totalRevenueCents =
        report.revenueTree.reduce((s: number, n: FinanceDreTreeNode) => s + n.amountCents, 0) ||
        totalRevenueCents;
      report.totalExpenseCents =
        report.expenseTree.reduce((s: number, n: FinanceDreTreeNode) => s + n.amountCents, 0) ||
        totalExpenseCents;""",
            """      const revenueTree = this.buildDreTree(categories, directAmounts, totals, 'receita');
      const expenseTree = this.buildDreTree(categories, directAmounts, totals, 'despesa');
      report.revenueTree = revenueTree;
      report.expenseTree = expenseTree;
      report.totalRevenueCents =
        revenueTree.reduce((s: number, n: FinanceDreTreeNode) => s + n.amountCents, 0) ||
        totalRevenueCents;
      report.totalExpenseCents =
        expenseTree.reduce((s: number, n: FinanceDreTreeNode) => s + n.amountCents, 0) ||
        totalExpenseCents;""",
        ),
    ],
)

patch_file(
    "packages/contracts/src/finance/dre.schema.ts",
    [
        (
            """export type FinanceDreTreeNode = FinanceDreLine & {
  nivel: number;
  directAmountCents: number;
  children?: FinanceDreTreeNode[];
};""",
            """export type FinanceDreTreeNode = FinanceDreLine & {
  nivel: number;
  directAmountCents: number;
  children: FinanceDreTreeNode[];
};""",
        ),
    ],
)

print("All patches applied.")
