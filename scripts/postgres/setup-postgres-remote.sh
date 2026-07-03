#!/bin/bash
# Habilita acesso remoto ao PostgreSQL na rede local (pgAdmin, etc.).
# Detecta automaticamente o cluster ONLINE (ex.: 17, não 15 parado).
# Uso: bash setup-postgres-remote.sh

set -euo pipefail

PG_PORT=5432
LAN_CIDR="192.168.100.0/24"

if ! sudo -n true 2>/dev/null; then
  echo "Será solicitada a senha sudo..."
  sudo true
fi

run_root() { sudo "$@"; }

PG_VERSION="$(pg_lsclusters -h 2>/dev/null | awk '$4 == "online" { print $1; exit }')"
if [ -z "$PG_VERSION" ]; then
  echo "ERRO: nenhum cluster PostgreSQL online encontrado."
  echo "Clusters:"
  pg_lsclusters || true
  exit 1
fi

PG_CLUSTER="main"
PG_CONF="/etc/postgresql/${PG_VERSION}/${PG_CLUSTER}/postgresql.conf"
PG_HBA="/etc/postgresql/${PG_VERSION}/${PG_CLUSTER}/pg_hba.conf"
TS="$(date +%Y%m%d%H%M%S)"

if [ ! -f "$PG_CONF" ]; then
  echo "ERRO: $PG_CONF não existe."
  exit 1
fi

LAN_IP="$(ip -4 addr show scope global 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | grep '^192\.168\.100\.' | head -1 || true)"
LAN_IP="${LAN_IP:-$(hostname -I 2>/dev/null | awk '{print $1}')}"
LAN_IP="${LAN_IP:-192.168.100.220}"

echo "== PostgreSQL remote setup =="
echo "Cluster: ${PG_VERSION}/${PG_CLUSTER} (online)"
pg_lsclusters | grep -E "^${PG_VERSION}[[:space:]]" || true
echo "Config:  $PG_CONF"
echo "pg_hba:  $PG_HBA"
echo "IP LAN:  $LAN_IP"
echo "Porta:   $PG_PORT"
echo ""

run_root cp "$PG_CONF" "${PG_CONF}.bak.${TS}"
run_root cp "$PG_HBA" "${PG_HBA}.bak.${TS}"
echo "Backups criados (.bak.${TS})"
echo ""

echo "== Ajustando postgresql.conf =="
run_root sed -i '/^listen_addresses[[:space:]]*=/d' "$PG_CONF"
run_root sed -i 's/^port[[:space:]]*=.*/port = 5432/' "$PG_CONF"

if grep -q "^#listen_addresses = 'localhost'" "$PG_CONF"; then
  run_root sed -i "/^#listen_addresses = 'localhost'/a listen_addresses = '*'" "$PG_CONF"
else
  echo "listen_addresses = '*'" | run_root tee -a "$PG_CONF" >/dev/null
fi

grep -E '^(listen_addresses|port)' "$PG_CONF"

echo ""
echo "== Ajustando pg_hba.conf =="
if ! run_root grep -qE "^host[[:space:]]+all[[:space:]]+all[[:space:]]+192\.168\.100\.0/24" "$PG_HBA"; then
  printf '\n# LAN pgAdmin %s\nhost    all    all    %s    scram-sha-256\n' "$TS" "$LAN_CIDR" | run_root tee -a "$PG_HBA" >/dev/null
  echo "Regra LAN adicionada."
else
  echo "Regra LAN já existe."
fi
run_root tail -3 "$PG_HBA"

echo ""
echo "== Firewall (UFW) =="
if command -v ufw >/dev/null 2>&1 && run_root ufw status 2>/dev/null | grep -q "Status: active"; then
  run_root ufw allow from "$LAN_CIDR" to any port "$PG_PORT" proto tcp comment 'PostgreSQL LAN' || true
else
  echo "UFW inativo ou ausente."
fi

echo ""
echo "== Reiniciando cluster ${PG_VERSION}/${PG_CLUSTER} =="
run_root pg_ctlcluster "$PG_VERSION" "$PG_CLUSTER" restart
sleep 2

export PGPASSWORD="${PGPASSWORD:-postgres}"
echo ""
echo "== Verificação =="
psql -h 127.0.0.1 -U postgres -d postgres -tAc "SHOW listen_addresses;" 2>/dev/null || true
run_root ss -tlnp | grep 5432 || true

if run_root ss -tlnp | grep -qE '0\.0\.0\.0:5432|\[::\]:5432|192\.168\.100\.[0-9]+:5432'; then
  echo ""
  echo "OK — Postgres acessível na rede em ${LAN_IP}:${PG_PORT}"
else
  echo ""
  echo "FALHA — confira logs:"
  echo "  sudo journalctl -u postgresql@${PG_VERSION}-${PG_CLUSTER} -n 40 --no-pager"
  exit 1
fi

echo ""
echo "== pgAdmin =="
echo "  Host:     ${LAN_IP}"
echo "  Port:     ${PG_PORT}"
echo "  Database: hubsaas"
echo "  User:     postgres"
