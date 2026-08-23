#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-/var/log/chatwoot_config_sync.log}"
DB_CONTAINER="${CHATWOOT_DB_CONTAINER:-}"
APP_CONTAINER="${CHATWOOT_APP_CONTAINER:-}"
DB_USER="${CHATWOOT_DB_USER:-chatwoot}"
DB_NAME="${CHATWOOT_DB_NAME:-chatwoot_production}"

BRAND_NAME="${CHATWOOT_BRAND_NAME:-CRM Agentico}"
INSTALLATION_NAME="${CHATWOOT_INSTALLATION_NAME:-CRM Agentico}"
PRIVACY_URL="${CHATWOOT_PRIVACY_URL:-}"
TERMS_URL="${CHATWOOT_TERMS_URL:-}"
BRAND_URL="${CHATWOOT_BRAND_URL:-}"
WIDGET_BRAND_URL="${CHATWOOT_WIDGET_BRAND_URL:-$BRAND_URL}"
SUPPORT_SCRIPT_URL="${CHATWOOT_SUPPORT_SCRIPT_URL:-}"

log() {
  local level="$1"
  local message="$2"
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$message" | tee -a "$LOG_FILE"
}

require_container() {
  local name="$1"
  if ! docker ps --format '{{.Names}}' | grep -qx "$name"; then
    log "ERROR" "Container '$name' is not running"
    exit 1
  fi
}

detect_container() {
  local pattern="$1"
  docker ps --format '{{.Names}}' | grep -E "$pattern" | head -n 1
}

sql_escape_yaml_value() {
  printf '%s' "$1" | sed "s/'/''/g"
}

config_sql() {
  local name="$1"
  local value="$2"
  [ -n "$value" ] || return 0
  local escaped
  escaped="$(sql_escape_yaml_value "$value")"
  cat <<SQL
UPDATE public.installation_configs
SET serialized_value = to_json('--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess
value: ${escaped}
'::text)
WHERE name = '${name}';
SQL
}

if [ -z "$DB_CONTAINER" ]; then
  DB_CONTAINER="$(detect_container '(^|-)chatwoot_postgres(-|$)')"
fi

if [ -z "$APP_CONTAINER" ]; then
  APP_CONTAINER="$(docker ps --format '{{.Names}}' | grep -E '(^|-)chatwoot(-|$)' | grep -Ev 'sidekiq|postgres|redis' | head -n 1)"
fi

require_container "$DB_CONTAINER"
require_container "$APP_CONTAINER"

log "INFO" "Synchronizing Chatwoot installation config"

SQL_COMMAND="$(
  config_sql "BRAND_NAME" "$BRAND_NAME"
  config_sql "INSTALLATION_NAME" "$INSTALLATION_NAME"
  config_sql "PRIVACY_URL" "$PRIVACY_URL"
  config_sql "TERMS_URL" "$TERMS_URL"
  config_sql "BRAND_URL" "$BRAND_URL"
  config_sql "WIDGET_BRAND_URL" "$WIDGET_BRAND_URL"
  config_sql "CHATWOOT_SUPPORT_SCRIPT_URL" "$SUPPORT_SCRIPT_URL"
)"

if [ -z "$SQL_COMMAND" ]; then
  log "INFO" "No config values provided"
  exit 0
fi

docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "$SQL_COMMAND" >>"$LOG_FILE" 2>&1
log "INFO" "Database config synchronized"

if docker exec "$APP_CONTAINER" sh -c "test -d /app/storage/public && cp -r /app/storage/public/. /app/public/ 2>/dev/null || true" >>"$LOG_FILE" 2>&1; then
  log "INFO" "Public assets synchronized"
else
  log "WARN" "Asset synchronization returned non-zero"
fi

log "INFO" "Completed"
