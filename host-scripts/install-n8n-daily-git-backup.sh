#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/opt/crm-agentico/bin}"
SCHEDULE="${N8N_DAILY_BACKUP_CRON:-17 3 * * *}"
COMMAND="$INSTALL_DIR/n8n-export-seed-commit"

if [ ! -x "$COMMAND" ]; then
  echo "Missing executable: $COMMAND" >&2
  exit 1
fi

tmp="$(mktemp)"
crontab -l 2>/dev/null | grep -vF "$COMMAND" > "$tmp" || true
{
  cat "$tmp"
  echo "$SCHEDULE $COMMAND >> /var/log/n8n-export-seed-commit.log 2>&1"
} | crontab -
rm -f "$tmp"

crontab -l | grep -F "$COMMAND"
