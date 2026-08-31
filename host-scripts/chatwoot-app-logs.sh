#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${CHATWOOT_CONTAINER:-crm-agentico-443xo5-chatwoot-1}"

exec docker logs -f --tail "${TAIL:-200}" "$CONTAINER"
