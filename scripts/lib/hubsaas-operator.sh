#!/bin/bash
# Helpers para operar o HubSaaS como outro usuário (ex.: igor → celio).
# Uso: source "$(dirname "$0")/../lib/hubsaas-operator.sh"

: "${HUBSAAS_OPERATOR_USER:=celio}"

hubsaas_operator_home() {
  getent passwd "$HUBSAAS_OPERATOR_USER" | cut -d: -f6
}

hubsaas_operator_uid() {
  id -u "$HUBSAAS_OPERATOR_USER"
}

hubsaas_operator_debian_root() {
  printf '%s/debian' "$(hubsaas_operator_home)"
}

hubsaas_operator_hubsaas_dir() {
  printf '%s/hubsaas' "$(hubsaas_operator_home)"
}

hubsaas_is_operator() {
  [ "$(id -un)" = "$HUBSAAS_OPERATOR_USER" ]
}

hubsaas_operator_user_env() {
  local uid runtime
  uid="$(hubsaas_operator_uid)"
  runtime="/run/user/$uid"
  printf 'XDG_RUNTIME_DIR=%s DBUS_SESSION_BUS_ADDRESS=unix:path=%s/bus' "$runtime" "$runtime"
}

# Executa comando no shell do usuário operador (hubsaas, debian, PATH).
hubsaas_as_operator() {
  local home debian
  home="$(hubsaas_operator_home)"
  debian="$(hubsaas_operator_debian_root)"
  sudo -u "$HUBSAAS_OPERATOR_USER" \
    HOME="$home" \
    USER="$HUBSAAS_OPERATOR_USER" \
    LOGNAME="$HUBSAAS_OPERATOR_USER" \
    DEBIAN_ROOT="$debian" \
    HUBSAAS_DIR="${HUBSAAS_DIR:-$home/hubsaas}" \
  bash -lc "$*"
}

# systemctl --user do operador (ngrok, etc.).
hubsaas_operator_systemctl_user() {
  local env
  env="$(hubsaas_operator_user_env)"
  # shellcheck disable=SC2086
  sudo -u "$HUBSAAS_OPERATOR_USER" env $env systemctl --user "$@"
}
