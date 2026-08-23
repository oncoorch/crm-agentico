#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${CRM_AGENTICO_REPO_DIR:-/opt/crm-agentico}"

export CHATWOOT_BRAND_NAME="${CHATWOOT_BRAND_NAME:-CRM-Komodo}"
export CHATWOOT_INSTALLATION_NAME="${CHATWOOT_INSTALLATION_NAME:-CRM-Komodo}"
export CHATWOOT_BRAND_URL="${CHATWOOT_BRAND_URL:-https://crm.oncoorch.com}"
export CHATWOOT_WIDGET_BRAND_URL="${CHATWOOT_WIDGET_BRAND_URL:-https://crm.oncoorch.com}"
export CHATWOOT_PRIVACY_URL="${CHATWOOT_PRIVACY_URL:-https://oncoorch.com/privacy}"
export CHATWOOT_TERMS_URL="${CHATWOOT_TERMS_URL:-https://oncoorch.com/terms}"

if [ -x "$REPO_DIR/scripts/chatwoot_config_sync.sh" ]; then
  exec "$REPO_DIR/scripts/chatwoot_config_sync.sh"
fi

if [ -x "$SCRIPT_DIR/../scripts/chatwoot_config_sync.sh" ]; then
  exec "$SCRIPT_DIR/../scripts/chatwoot_config_sync.sh"
fi

echo "chatwoot_config_sync.sh not found. Set CRM_AGENTICO_REPO_DIR or run from the repo." >&2
exit 1
