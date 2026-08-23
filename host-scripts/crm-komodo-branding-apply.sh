#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${CRM_AGENTICO_REPO_DIR:-/opt/crm-agentico}"
SOURCE_DIR="${CHATWOOT_BRANDING_SOURCE_DIR:-/opt/crm_branding}"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Branding source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

export CHATWOOT_BRANDING_SOURCE_DIR="$SOURCE_DIR"

if [ -x "$REPO_DIR/scripts/chatwoot_branding_assets.sh" ]; then
  "$REPO_DIR/scripts/chatwoot_branding_assets.sh"
elif [ -x "$SCRIPT_DIR/../scripts/chatwoot_branding_assets.sh" ]; then
  "$SCRIPT_DIR/../scripts/chatwoot_branding_assets.sh"
else
  echo "chatwoot_branding_assets.sh not found. Set CRM_AGENTICO_REPO_DIR or run from the repo." >&2
  exit 1
fi

if [ -x "$SCRIPT_DIR/crm-komodo-config-sync" ]; then
  "$SCRIPT_DIR/crm-komodo-config-sync"
else
  "$SCRIPT_DIR/crm-komodo-config-sync.sh"
fi
