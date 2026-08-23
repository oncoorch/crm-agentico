#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${CRM_AGENTICO_REPO_DIR:-/opt/crm-agentico}"
SOURCE_DIR="${1:-${N8N_SEED_SOURCE_CREDENTIALS_DIR:-private/n8n-seed/source-credentials}}"

cd "$REPO_DIR"
python3 scripts/build_n8n_seed_credentials_bundle.py --credentials-dir "$SOURCE_DIR"

echo
echo "Paste this file content into Dokploy as N8N_SEED_CREDENTIALS_TGZ_B64:"
echo "$REPO_DIR/private/n8n-seed/N8N_SEED_CREDENTIALS_TGZ_B64.txt"
