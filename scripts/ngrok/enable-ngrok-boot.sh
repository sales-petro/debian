#!/bin/bash
# Roda UMA VEZ com sudo para o ngrok subir no boot sem precisar de login.
# Uso: sudo ./enable-ngrok-boot.sh

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
if [ "$EUID" -ne 0 ]; then
  echo "Execute com sudo: sudo $0"
  exit 1
fi

loginctl enable-linger "$TARGET_USER"
echo "Linger ativado para $TARGET_USER"
echo "Os serviços hubsaas-backend e hubsaas-frontend sobem automaticamente no boot."
