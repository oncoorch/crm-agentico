#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${CRM_AGENTICO_REPO_DIR:-/opt/crm-agentico}"
N8N_CONTAINER="${N8N_CONTAINER:-}"
BRANCH="${N8N_SEED_BRANCH:-main}"

cd "$REPO_DIR"

if [ -z "$N8N_CONTAINER" ]; then
  N8N_CONTAINER="$(docker ps --format '{{.Names}}' | grep -E '(^|-)n8n(-|$)' | grep -Ev 'postgres|redis' | head -n 1)"
fi

if [ -z "$N8N_CONTAINER" ]; then
  echo "n8n container not found" >&2
  exit 1
fi

STAMP="$(date '+%Y%m%d-%H%M%S')"
WORK_DIR="private/n8n-live-export/$STAMP"
mkdir -p "$WORK_DIR"

docker exec "$N8N_CONTAINER" sh -lc 'rm -rf /tmp/n8n-seed-export && mkdir -p /tmp/n8n-seed-export/workflows'
docker exec "$N8N_CONTAINER" n8n export:workflow --backup --output=/tmp/n8n-seed-export/workflows
docker exec "$N8N_CONTAINER" sh -lc 'tar -czf /tmp/n8n-seed-export.tar.gz -C /tmp n8n-seed-export'
docker cp "$N8N_CONTAINER:/tmp/n8n-seed-export.tar.gz" "$WORK_DIR/n8n-seed-export.tar.gz"
tar -xzf "$WORK_DIR/n8n-seed-export.tar.gz" -C "$WORK_DIR"

python3 scripts/sanitize_n8n_workflows.py \
  --input-dir "$WORK_DIR/n8n-seed-export/workflows" \
  --output-dir n8n-seed/workflows \
  --replace

git add n8n-seed/workflows
if git diff --cached --quiet; then
  echo "No workflow changes to commit"
  exit 0
fi

git commit -m "Sync n8n workflows from live instance $STAMP"
git push origin "$BRANCH"
