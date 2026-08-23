#!/usr/bin/env bash
set -euo pipefail

N8N_CONTAINER="${N8N_CONTAINER:-n8n}"
BACKUP_ROOT="${N8N_BACKUP_ROOT:-./private/n8n-backups}"
STAMP="$(date '+%Y%m%d-%H%M%S')"
OUT_DIR="$BACKUP_ROOT/$STAMP"

mkdir -p "$OUT_DIR"

if ! docker ps --format '{{.Names}}' | grep -qx "$N8N_CONTAINER"; then
  echo "n8n container '$N8N_CONTAINER' is not running" >&2
  exit 1
fi

docker exec "$N8N_CONTAINER" sh -c 'rm -rf /tmp/n8n-export && mkdir -p /tmp/n8n-export/workflows /tmp/n8n-export/credentials'
docker exec "$N8N_CONTAINER" n8n export:workflow --backup --output=/tmp/n8n-export/workflows
docker exec "$N8N_CONTAINER" n8n export:credentials --backup --output=/tmp/n8n-export/credentials
docker exec "$N8N_CONTAINER" n8n export:credentials --all --decrypted --pretty --output=/tmp/n8n-export/credentials-decrypted.json
docker exec "$N8N_CONTAINER" sh -c 'tar -czf /tmp/n8n-export.tar.gz -C /tmp n8n-export'
docker cp "$N8N_CONTAINER:/tmp/n8n-export.tar.gz" "$OUT_DIR/n8n-export.tar.gz"

tar -xzf "$OUT_DIR/n8n-export.tar.gz" -C "$OUT_DIR"
find "$OUT_DIR/n8n-export/workflows" -type f -name '*.json' -print | sort > "$OUT_DIR/workflow-files.txt"

echo "n8n backup created at $OUT_DIR"
