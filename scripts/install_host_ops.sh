#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/opt/crm-agentico/bin}"
REPO_DIR="${CRM_AGENTICO_REPO_DIR:-$(pwd)}"

install -d -m 0755 "$INSTALL_DIR"
install -m 0755 host-scripts/crm-komodo-config-sync.sh "$INSTALL_DIR/crm-komodo-config-sync"
install -m 0755 host-scripts/crm-komodo-branding-apply.sh "$INSTALL_DIR/crm-komodo-branding-apply"
install -m 0755 host-scripts/n8n-seed-credentials-build.sh "$INSTALL_DIR/n8n-seed-credentials-build"
install -m 0755 host-scripts/n8n-export-seed-commit.sh "$INSTALL_DIR/n8n-export-seed-commit"
install -m 0755 host-scripts/install-n8n-daily-git-backup.sh "$INSTALL_DIR/install-n8n-daily-git-backup"

cat > "$INSTALL_DIR/env" <<EOF
export CRM_AGENTICO_REPO_DIR="$REPO_DIR"
EOF

echo "Installed host operations scripts in $INSTALL_DIR"
echo "Run:"
echo "  source $INSTALL_DIR/env"
echo "  $INSTALL_DIR/crm-komodo-config-sync"
echo "  $INSTALL_DIR/crm-komodo-branding-apply"
echo "  $INSTALL_DIR/n8n-export-seed-commit"
echo "  $INSTALL_DIR/install-n8n-daily-git-backup"
