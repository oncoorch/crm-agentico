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
CHATWOOT_IMAGE=omnicem/chatwoot:reports-c0b1b1c3e
```

Si el registry es privado, configurar credenciales del registry en Dokploy.

## 4. Dominios en Dokploy

Configurar:

```text
crm.oncoorch.com             -> chatwoot      port 3000
automation-crm.oncoorch.com  -> n8n           port 5678
evolution.oncoorch.com       -> evolution     port 8080
crm-agent.oncoorch.com       -> mcp_agentico  port 8000
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
