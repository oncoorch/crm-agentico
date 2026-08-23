#!/usr/bin/env sh
set -eu

mkdir -p /app/public /app/storage/public
cp -R /tmp/crm-komodo-public/. /app/public/
cp -R /tmp/crm-komodo-public/. /app/storage/public/

ruby <<'RUBY'
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

rm -rf /tmp/crm-komodo-public
