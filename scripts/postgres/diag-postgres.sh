#!/bin/bash
# Diagnóstico rápido do PostgreSQL (cluster ativo vs configs antigas).
set -euo pipefail

export PGPASSWORD="${PGPASSWORD:-postgres}"

echo "== Clusters =="
pg_lsclusters || true

echo ""
echo "== Runtime (psql) =="
psql -h 127.0.0.1 -U postgres -d postgres -tAc "SHOW config_file;" 2>/dev/null || echo "(psql falhou)"
psql -h 127.0.0.1 -U postgres -d postgres -tAc "SHOW listen_addresses;" 2>/dev/null || true
psql -h 127.0.0.1 -U postgres -d postgres -tAc "SHOW port;" 2>/dev/null || true

ACTIVE_CONF="$(psql -h 127.0.0.1 -U postgres -d postgres -tAc "SHOW config_file;" 2>/dev/null || true)"
echo ""
echo "== postgresql.conf ativo =="
if [ -n "$ACTIVE_CONF" ] && [ -f "$ACTIVE_CONF" ]; then
  grep -E '^(listen_addresses|port)' "$ACTIVE_CONF" || echo "(sem listen_addresses — default localhost)"
else
  echo "não encontrado"
fi

echo ""
echo "== Sockets 5432 =="
ss -tlnp 2>/dev/null | grep 5432 || sudo ss -tlnp | grep 5432 || true
