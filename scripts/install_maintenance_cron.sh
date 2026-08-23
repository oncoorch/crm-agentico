#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_TARGET="${SYNC_TARGET:-/usr/local/bin/update_chatwoot.sh}"
BRANDING_TARGET="${BRANDING_TARGET:-/usr/local/bin/apply_chatwoot_branding.sh}"
SYNC_CRON="${SYNC_CRON:-*/30 * * * *}"
BRANDING_CRON="${BRANDING_CRON:-17 * * * *}"

install -m 0755 "$BASE_DIR/chatwoot_config_sync.sh" "$SYNC_TARGET"
install -m 0755 "$BASE_DIR/chatwoot_branding_assets.sh" "$BRANDING_TARGET"

tmp="$(mktemp)"
crontab -l 2>/dev/null | grep -vF "$SYNC_TARGET" | grep -vF "$BRANDING_TARGET" > "$tmp" || true
{
  cat "$tmp"
  echo "$SYNC_CRON $SYNC_TARGET"
  echo "$BRANDING_CRON $BRANDING_TARGET"
} | crontab -
rm -f "$tmp"

echo "Installed maintenance cron:"
crontab -l | grep -E "$SYNC_TARGET|$BRANDING_TARGET"
