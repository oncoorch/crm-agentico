#!/usr/bin/env bash
set -euo pipefail

docker compose --env-file "${1:-.env.example}" -f compose.yml config >/tmp/crm-agentico-compose.rendered.yml
echo "Rendered compose: /tmp/crm-agentico-compose.rendered.yml"
