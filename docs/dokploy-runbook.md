# Runbook de despliegue en Dokploy

## 1. DNS

Crear en Cloudflare registros A o CNAME hacia el VPS NICOP:

```text
crm.oncoorch.com
automation-crm.oncoorch.com
evolution.oncoorch.com
crm-agent.oncoorch.com
```

Para la primera emision de Let's Encrypt, usar `DNS only` si Cloudflare proxied genera errores TLS. Luego se puede volver a proxied.

## 2. Proyecto en Dokploy

Crear proyecto:

```text
CRM Agentico
```

Crear servicio tipo Compose:

```text
Repository: oncoorch/crm-agentico
Branch: main
Compose path: compose.yml
Auto deploy: enabled
```

## 3. Variables obligatorias

Usar `.env.example` como plantilla y completar en Dokploy.

Minimo:

```text
CRM_PUBLIC_URL
N8N_PUBLIC_URL
EVOLUTION_PUBLIC_URL
MCP_PUBLIC_URL
CHATWOOT_POSTGRES_PASSWORD
CHATWOOT_REDIS_PASSWORD
CHATWOOT_SECRET_KEY_BASE
N8N_POSTGRES_PASSWORD
N8N_REDIS_PASSWORD
N8N_ENCRYPTION_KEY
EVOLUTION_API_KEY
EVOLUTION_POSTGRES_PASSWORD
MCP_SHARED_SECRET
```

Si se usa imagen custom autorizada:

```text
CHATWOOT_IMAGE=chatwoot/chatwoot:v4.6.0
CHATWOOT_RUNTIME_IMAGE=crm-agentico-chatwoot:latest
```

`CHATWOOT_IMAGE` es la imagen base. Si tienes una imagen entregada por el
proveedor/licencia, reemplazala ahi. `CHATWOOT_RUNTIME_IMAGE` es la imagen final
que Dokploy construye desde este repositorio con branding y login parcheado.

Evolution API:

```text
EVOLUTION_IMAGE=evoapicloud/evolution-api:v2.2.3
```

Si el registry es privado, configurar credenciales del registry en Dokploy.

## 4. Dominios en Dokploy

Configurar:

```text
crm.oncoorch.com             -> chatwoot      port 3000
automation-crm.oncoorch.com  -> n8n           port 5678
evolution.oncoorch.com       -> evolution     port 8080
crm-agent.oncoorch.com       -> mcp_agentico  port 8000
prompter.oncoorch.com        -> prompt_manager port 3100
```

No publicar:

```text
chatwoot_postgres
chatwoot_redis
n8n_postgres
n8n_redis
evolution_postgres
evolution_redis
```

## Variables en Dokploy

Coloca las variables en el `Environment` del recurso Docker Compose. Dokploy
crea el `.env` del deploy y Compose las lee con `${VARIABLE}`.

La variable de credenciales n8n debe ir en una sola linea:

```text
N8N_SEED_CREDENTIALS_TGZ_B64=<contenido completo de private/n8n-seed/N8N_SEED_CREDENTIALS_TGZ_B64.txt>
```

Si ya esta en el `Environment` del recurso, no hace falta duplicarla en
`Project Environment`. Usa `Project Environment` solo para variables compartidas
por varias aplicaciones y referencialas desde el recurso.

## 5. Smoke tests

```bash
curl -I https://crm.oncoorch.com/
curl -I https://automation-crm.oncoorch.com/
curl -I https://evolution.oncoorch.com/
curl -sS https://crm-agent.oncoorch.com/healthz
```

Lead test:

```bash
curl -sS -X POST https://crm-agent.oncoorch.com/leads \
  -H 'content-type: application/json' \
  -H "x-crm-secret: $MCP_SHARED_SECRET" \
  --data '{"name":"Lead de prueba","email":"test@example.com","source":"smoke","message":"Prueba"}'
```

## 6. Integraciones

### n8n

Configurar `N8N_LEAD_WEBHOOK_URL` con un webhook productivo de n8n para recibir leads desde `mcp_agentico`.

### WhatsApp con Evolution API

Este repositorio incluye un script idempotente para dejar listas las dos rutas
de WhatsApp usadas en NICOP:

```bash
scripts/evolution_configure_whatsapp.sh
```

Configura:

- `NICOP USA` -> integracion nativa Evolution/Chatwoot -> inbox `NICOP USA WhatsApp` -> bot `Koko`.
- `Oncoorch ECU 593` -> webhook directo a n8n `https://automation-crm.oncoorch.com/webhook/wabarenew`.

Variables opcionales:

```text
EVOLUTION_CONTAINER=crm-agentico-443xo5-evolution-1
CHATWOOT_CONTAINER=crm-agentico-443xo5-chatwoot-1
CHATWOOT_ACCOUNT_ID=1
CHATWOOT_USER_EMAIL=angel.yaguana@oncoorch.com
NICOP_USA_INSTANCE=NICOP USA
NICOP_USA_INBOX_NAME=NICOP USA WhatsApp
NICOP_USA_BOT_NAME=Koko
HENDEL_INSTANCE=Oncoorch ECU 593
HENDEL_N8N_WEBHOOK_URL=https://automation-crm.oncoorch.com/webhook/wabarenew
```

No se guardan tokens en Git. El script toma `AUTHENTICATION_API_KEY` desde el
contenedor de Evolution y el token de Chatwoot desde el usuario configurado.

Para la logica de bot/humano, usar etiquetas de Chatwoot en n8n:

- `bot_on`: el agente puede responder.
- `bot_off`: la conversacion queda en manos humanas.
- `handover_requested`: el agente pidio derivacion.
- `human_active`: un asesor esta interviniendo.

Los workflows deben ignorar conversaciones con `bot_off` o `human_active` y
pueden reactivar el bot cuando el asesor quite esas etiquetas o cierre la
conversacion.

### Supabase

Configurar:

```text
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
SUPABASE_LEADS_TABLE
```

La tabla sugerida:

```sql
create table if not exists leads (
  id uuid primary key default gen_random_uuid(),
  name text,
  email text,
  phone text,
  source text not null default 'website',
  message text,
  metadata jsonb not null default '{}'::jsonb,
  client_ip text,
  created_at timestamptz not null default now()
);
```
