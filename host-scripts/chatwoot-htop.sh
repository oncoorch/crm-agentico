#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${CHATWOOT_CONTAINER:-crm-agentico-443xo5-chatwoot-1}"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "Container not running: $CONTAINER" >&2
  exit 1
fi

docker exec -it "$CONTAINER" sh -lc 'if command -v htop >/dev/null 2>&1; then exec htop; fi; if command -v apt-get >/dev/null 2>&1; then apt-get update >/dev/null && apt-get install -y htop >/dev/null && exec htop; fi; exec top'
