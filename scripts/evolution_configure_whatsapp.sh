#!/usr/bin/env bash
set -euo pipefail

EVOLUTION_CONTAINER="${EVOLUTION_CONTAINER:-crm-agentico-443xo5-evolution-1}"
CHATWOOT_CONTAINER="${CHATWOOT_CONTAINER:-crm-agentico-443xo5-chatwoot-1}"
CHATWOOT_ACCOUNT_ID="${CHATWOOT_ACCOUNT_ID:-1}"
CHATWOOT_USER_EMAIL="${CHATWOOT_USER_EMAIL:-angel.yaguana@oncoorch.com}"

NICOP_USA_INSTANCE="${NICOP_USA_INSTANCE:-NICOP USA}"
NICOP_USA_INBOX_NAME="${NICOP_USA_INBOX_NAME:-NICOP USA WhatsApp}"
NICOP_USA_BOT_NAME="${NICOP_USA_BOT_NAME:-Koko}"

HENDEL_INSTANCE="${HENDEL_INSTANCE:-Oncoorch ECU 593}"
HENDEL_N8N_WEBHOOK_URL="${HENDEL_N8N_WEBHOOK_URL:-https://automation-crm.oncoorch.com/webhook/wabarenew}"

require_container() {
  local name="$1"
  if ! docker ps --format '{{.Names}}' | grep -qx "$name"; then
    echo "Container not running: $name" >&2
    exit 1
  fi
}

urlencode() {
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

evolution_post_json() {
  local path="$1"
  local json_file="$2"
  docker exec -i -e API_KEY="$EVOLUTION_API_KEY" "$EVOLUTION_CONTAINER" sh -lc \
    'cat >/tmp/evolution-payload.json;
     wget -qO- --header="Content-Type: application/json" --header="apikey: $API_KEY" \
       --post-file=/tmp/evolution-payload.json "http://127.0.0.1:8080/'"$path"'"' < "$json_file" >/dev/null
}

require_container "$EVOLUTION_CONTAINER"
require_container "$CHATWOOT_CONTAINER"

EVOLUTION_API_KEY="${EVOLUTION_API_KEY:-$(docker inspect "$EVOLUTION_CONTAINER" \
  --format '{{range .Config.Env}}{{println .}}{{end}}' | sed -n 's/^AUTHENTICATION_API_KEY=//p')}"

CHATWOOT_API_ACCESS_TOKEN="${CHATWOOT_API_ACCESS_TOKEN:-$(docker exec -e CHATWOOT_USER_EMAIL="$CHATWOOT_USER_EMAIL" "$CHATWOOT_CONTAINER" bundle exec rails runner \
  'u=User.find_by(email: ENV.fetch("CHATWOOT_USER_EMAIL")); puts u.access_token.token' \
  2>/dev/null | tail -n 1 | tr -d '\r')}"

if [ -z "$EVOLUTION_API_KEY" ] || [ -z "$CHATWOOT_API_ACCESS_TOKEN" ]; then
  echo "Missing Evolution API key or Chatwoot API token." >&2
  exit 1
fi

nicop_encoded="$(urlencode "$NICOP_USA_INSTANCE")"
hendel_encoded="$(urlencode "$HENDEL_INSTANCE")"

tmp_chatwoot="$(mktemp)"
tmp_webhook="$(mktemp)"
trap 'rm -f "$tmp_chatwoot" "$tmp_webhook"' EXIT

cat > "$tmp_chatwoot" <<JSON
{
  "enabled": true,
  "accountId": "$CHATWOOT_ACCOUNT_ID",
  "token": "$CHATWOOT_API_ACCESS_TOKEN",
  "url": "http://chatwoot:3000",
  "signMsg": false,
  "signDelimiter": "\\n",
  "nameInbox": "$NICOP_USA_INBOX_NAME",
  "reopenConversation": true,
  "conversationPending": true,
  "autoCreate": true,
  "importContacts": false,
  "mergeBrazilContacts": false,
  "importMessages": false,
  "daysLimitImportMessages": 0,
  "ignoreJids": ["@g.us"]
}
JSON

cat > "$tmp_webhook" <<JSON
{
  "webhook": {
    "enabled": true,
    "url": "$HENDEL_N8N_WEBHOOK_URL",
    "webhookByEvents": false,
    "webhookBase64": true,
    "events": ["MESSAGES_UPSERT", "MESSAGES_UPDATE", "SEND_MESSAGE"]
  }
}
JSON

evolution_post_json "chatwoot/set/$nicop_encoded" "$tmp_chatwoot"
evolution_post_json "webhook/set/$hendel_encoded" "$tmp_webhook"

docker exec -e NICOP_USA_INBOX_NAME="$NICOP_USA_INBOX_NAME" -e NICOP_USA_BOT_NAME="$NICOP_USA_BOT_NAME" \
  "$CHATWOOT_CONTAINER" bundle exec rails runner '
    bot = AgentBot.find_by!(name: ENV.fetch("NICOP_USA_BOT_NAME"))
    inbox = Inbox.find_by!(name: ENV.fetch("NICOP_USA_INBOX_NAME"))
    AgentBotInbox.find_or_create_by!(agent_bot_id: bot.id, inbox_id: inbox.id)
  ' >/dev/null

echo "WhatsApp integrations configured:"
echo "- $NICOP_USA_INSTANCE -> Evolution Chatwoot integration -> $NICOP_USA_INBOX_NAME -> $NICOP_USA_BOT_NAME"
echo "- $HENDEL_INSTANCE -> Evolution webhook -> $HENDEL_N8N_WEBHOOK_URL"
