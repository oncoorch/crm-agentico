#!/usr/bin/env bash
set -euo pipefail

APP_CONTAINER="${CHATWOOT_APP_CONTAINER:-chatwoot}"
SOURCE_DIR="${CHATWOOT_BRANDING_SOURCE_DIR:-./branding/chatwoot/public}"
TARGET_DIR="${CHATWOOT_BRANDING_TARGET_DIR:-/app/storage/public}"
LOG_FILE="${LOG_FILE:-/var/log/chatwoot_branding_assets.log}"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

if ! docker ps --format '{{.Names}}' | grep -qx "$APP_CONTAINER"; then
  log "ERROR container '$APP_CONTAINER' is not running"
  exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
  log "WARN source directory '$SOURCE_DIR' does not exist; nothing to copy"
  exit 0
fi

log "Copying branding assets from $SOURCE_DIR to $APP_CONTAINER:$TARGET_DIR"
docker exec "$APP_CONTAINER" sh -c "mkdir -p '$TARGET_DIR'"
docker cp "$SOURCE_DIR/." "$APP_CONTAINER:$TARGET_DIR/"
docker exec "$APP_CONTAINER" sh -c "cp -r '$TARGET_DIR'/. /app/public/ 2>/dev/null || true"
log "Branding assets applied"
