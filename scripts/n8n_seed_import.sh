#!/usr/bin/env sh
set -eu

SEED_ROOT="${N8N_SEED_ROOT:-/opt/n8n-seed}"
WORKFLOW_DIR="${N8N_SEED_WORKFLOW_DIR:-$SEED_ROOT/workflows}"
TMP_ROOT="${N8N_SEED_TMP_ROOT:-/tmp/n8n-seed}"
MARKER_DIR="${N8N_SEED_MARKER_DIR:-/home/node/.n8n/seed-markers}"
PROJECT_ID="${N8N_SEED_PROJECT_ID:-}"
IMPORT_CREDENTIALS="${N8N_SEED_IMPORT_CREDENTIALS:-true}"
IMPORT_WORKFLOWS="${N8N_SEED_IMPORT_WORKFLOWS:-true}"

log() {
  printf '[n8n-seed] %s\n' "$*"
}

project_arg() {
  if [ -n "$PROJECT_ID" ]; then
    printf -- '--projectId=%s' "$PROJECT_ID"
  fi
}

resolve_project_id() {
  if [ -n "$PROJECT_ID" ]; then
    return 0
  fi

  if [ ! -f "${N8N_SEED_RESOLVE_PROJECT_SCRIPT:-/usr/local/bin/n8n_seed_resolve_project.js}" ]; then
    return 0
  fi

  export NODE_PATH="${NODE_PATH:-/usr/local/lib/node_modules/n8n/node_modules}"
  resolved="$(node "${N8N_SEED_RESOLVE_PROJECT_SCRIPT:-/usr/local/bin/n8n_seed_resolve_project.js}" 2>/dev/null || true)"
  if [ -n "$resolved" ]; then
    PROJECT_ID="$resolved"
    export N8N_SEED_PROJECT_ID="$PROJECT_ID"
    log "resolved n8n project id: $PROJECT_ID"
  else
    log "could not resolve n8n project id; using n8n CLI default project behavior"
  fi
}

wait_for_db() {
  tries="${N8N_SEED_DB_WAIT_TRIES:-60}"
  i=1
  while [ "$i" -le "$tries" ]; do
    if n8n list:workflow --onlyId >/dev/null 2>&1; then
      return 0
    fi
    log "waiting for n8n database ($i/$tries)"
    i=$((i + 1))
    sleep 5
  done
  log "database did not become ready"
  return 1
}

prepare_credentials() {
  rm -rf "$TMP_ROOT"
  mkdir -p "$TMP_ROOT/credentials" "$MARKER_DIR"

  if [ -n "${N8N_SEED_CREDENTIALS_TGZ_B64:-}" ]; then
    log "decoding credentials bundle from N8N_SEED_CREDENTIALS_TGZ_B64"
    printf '%s' "$N8N_SEED_CREDENTIALS_TGZ_B64" | base64 -d > "$TMP_ROOT/credentials.tar.gz"
    tar -xzf "$TMP_ROOT/credentials.tar.gz" -C "$TMP_ROOT/credentials"
    return 0
  fi

  if [ -d "$SEED_ROOT/credentials" ]; then
    log "using credentials directory from $SEED_ROOT/credentials"
    cp -R "$SEED_ROOT/credentials/." "$TMP_ROOT/credentials/"
    return 0
  fi

  return 1
}

import_credentials() {
  [ "$IMPORT_CREDENTIALS" = "true" ] || {
    log "credential import disabled"
    return 0
  }

  if ! prepare_credentials; then
    log "no credential seed configured; skipping credentials"
    return 0
  fi

  count="$(find "$TMP_ROOT/credentials" -type f -name '*.json' | wc -l | tr -d ' ')"
  if [ "$count" = "0" ]; then
    log "credential seed is empty"
    return 0
  fi

  log "importing $count credentials"
  if [ -n "$PROJECT_ID" ]; then
    n8n import:credentials --separate --input="$TMP_ROOT/credentials" "$(project_arg)"
  else
    n8n import:credentials --separate --input="$TMP_ROOT/credentials"
  fi
}

import_workflows() {
  [ "$IMPORT_WORKFLOWS" = "true" ] || {
    log "workflow import disabled"
    return 0
  }

  if [ ! -d "$WORKFLOW_DIR" ]; then
    log "workflow seed directory does not exist: $WORKFLOW_DIR"
    return 0
  fi

  count="$(find "$WORKFLOW_DIR" -type f -name '*.json' | wc -l | tr -d ' ')"
  if [ "$count" = "0" ]; then
    log "workflow seed is empty"
    return 0
  fi

  log "importing $count workflows"
  if [ -n "$PROJECT_ID" ]; then
    n8n import:workflow --separate --input="$WORKFLOW_DIR" "$(project_arg)"
  else
    n8n import:workflow --separate --input="$WORKFLOW_DIR"
  fi
}

assign_folders() {
  if [ "${N8N_SEED_ASSIGN_FOLDERS:-true}" != "true" ]; then
    log "folder assignment disabled"
    return 0
  fi

  if [ ! -f "${N8N_SEED_ASSIGN_FOLDERS_SCRIPT:-/usr/local/bin/n8n_seed_assign_folders.js}" ]; then
    log "folder assignment script not found; skipping"
    return 0
  fi

  export NODE_PATH="${NODE_PATH:-/usr/local/lib/node_modules/n8n/node_modules}"
  node "${N8N_SEED_ASSIGN_FOLDERS_SCRIPT:-/usr/local/bin/n8n_seed_assign_folders.js}"
}

wait_for_db
resolve_project_id
import_credentials
import_workflows
assign_folders
log "seed import completed"
