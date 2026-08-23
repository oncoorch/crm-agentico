#!/usr/bin/env bash
set -euo pipefail

APP_CONTAINER="${CHATWOOT_APP_CONTAINER:-}"
LOG_FILE="${LOG_FILE:-/var/log/chatwoot_superadmin_ui_patch.log}"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

if [ -z "$APP_CONTAINER" ]; then
  APP_CONTAINER="$(docker ps --format '{{.Names}}' | grep -E '(^|-)chatwoot(-|$)' | grep -Ev 'sidekiq|postgres|redis' | head -n 1)"
fi

if ! docker ps --format '{{.Names}}' | grep -qx "$APP_CONTAINER"; then
  log "ERROR container '$APP_CONTAINER' is not running"
  exit 1
fi

PATCH_FILE="$(mktemp)"
cat >"$PATCH_FILE" <<'RUBY'
FILES = [
  '/app/app/views/super_admin/devise/sessions/new.html.erb',
  '/app/app/views/installation/onboarding/index.html.erb'
].freeze

REPLACEMENTS = {
  'SuperAdmin | Chatwoot' => 'SuperAdmin | CRM-Komodo',
  'alt="Chatwoot"' => 'alt="CRM-Komodo"',
  'Howdy, admin 👋' => 'Bienvenido Onconauta! 👋',
  'Howdy, Welcome to Chatwoot 👋' => 'Bienvenido Onconauta! 👋',
  'Email Address' => 'Correo electronico',
  'Email eg: someone@example.com' => 'usuario@oncoorch.com',
  'Password' => 'Contrasena',
  '<span>Login</span>' => '<span>Iniciar sesion</span>',
  'Finish Setup' => 'Finalizar configuracion'
}.freeze

FILES.each do |path|
  next unless File.file?(path)

  backup = "#{path}.crm-komodo.bak"
  File.write(backup, File.read(path)) unless File.exist?(backup)

  content = File.read(path)
  REPLACEMENTS.each { |from, to| content = content.gsub(from, to) }

  unless content.include?('/crm-komodo-superadmin.css')
    content = content.sub('</head>', '    <link rel="stylesheet" href="/crm-komodo-superadmin.css">' + "\n  </head>")
  end

  File.write(path, content)
end

navigation = '/app/app/views/super_admin/application/_navigation.html.erb'
if File.file?(navigation)
  content = File.read(navigation)
  content = content.gsub("alt: 'Chatwoot Admin Dashboard'", "alt: 'CRM-Komodo Admin Dashboard'")
  content = content.gsub('>Chatwoot <', '>CRM-Komodo <')
  File.write(navigation, content)
end
RUBY

log "Patching Chatwoot SuperAdmin UI in $APP_CONTAINER"
docker cp "$PATCH_FILE" "$APP_CONTAINER:/tmp/crm-komodo-superadmin-patch.rb" >>"$LOG_FILE" 2>&1
docker exec "$APP_CONTAINER" ruby /tmp/crm-komodo-superadmin-patch.rb >>"$LOG_FILE" 2>&1
rm -f "$PATCH_FILE"

log "SuperAdmin UI patch applied"
