#!/bin/bash
# Resolve a raiz do repo debian (contém env-servidor/ e scripts/).
# Uso: source "$(dirname "$0")/../lib/debian-root.sh"

if [ -z "${DEBIAN_ROOT:-}" ]; then
  _debian_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DEBIAN_ROOT="$(cd "$_debian_lib/../.." && pwd)"
  export DEBIAN_ROOT
fi
