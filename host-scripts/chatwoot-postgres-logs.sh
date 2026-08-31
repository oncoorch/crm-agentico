#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${CHATWOOT_POSTGRES_CONTAINER:-crm-agentico-443xo5-chatwoot_postgres-1}"

exec docker logs -f --tail "${TAIL:-200}" "$CONTAINER"
