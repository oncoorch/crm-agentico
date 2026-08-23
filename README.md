# CRM Agentico

Stack Docker para operar un CRM conversacional interno integrado con agentes, n8n, WhatsApp/Evolution API y fuentes externas como Supabase.

La base del CRM es Chatwoot o una imagen derivada autorizada por la organizacion. Este repositorio no incluye parches de licencia, credenciales, dumps de bases de datos ni archivos de marca propietarios.

## Servicios

- `chatwoot`: aplicacion web/API del CRM.
- `chatwoot_sidekiq`: jobs asincronos de Chatwoot.
- `chatwoot_postgres`: PostgreSQL 15 con pgvector.
- `chatwoot_redis`: Redis dedicado de Chatwoot.
- `n8n`: automatizacion y orquestacion de flujos.
- `n8n_postgres`: PostgreSQL dedicado de n8n.
- `n8n_redis`: Redis dedicado de n8n.
- `evolution`: Evolution API para WhatsApp.
- `evolution_postgres` y `evolution_redis`: persistencia de Evolution.
- `mcp_agentico`: bridge interno para leads, webhooks y herramientas del agente.
- `adminer`: perfil opcional de diagnostico.

## Despliegue en Dokploy

1. Crear un proyecto nuevo en Dokploy, por ejemplo `CRM Agentico`.
2. Crear un servicio tipo Compose apuntando a `oncoorch/crm-agentico`, rama `main`.
3. Usar `compose.yml` como compose path.
4. Configurar las variables de entorno a partir de `.env.example`.
5. Crear dominios en Dokploy:
   - `crm.oncoorch.com` -> servicio `chatwoot`, puerto `3000`.
   - `automation-crm.oncoorch.com` -> servicio `n8n`, puerto `5678`.
   - `evolution.oncoorch.com` -> servicio `evolution`, puerto `8080`.
   - `crm-agent.oncoorch.com` -> servicio `mcp_agentico`, puerto `8000`.
6. Activar HTTPS con Let's Encrypt.

Para exponer solo lo necesario, no publiques Postgres ni Redis. `adminer` debe usarse solo con perfil `tools` y Basic Auth/allowlist.

## Variables minimas

Copiar `.env.example` y completar secretos en Dokploy:

```bash
cp .env.example .env
```

Generar secretos:

```bash
openssl rand -hex 32
openssl rand -base64 64 | tr -d '\n'
```

## Integracion de leads

La web publica puede enviar leads a:

```text
POST https://crm-agent.oncoorch.com/leads
```

El bridge normaliza el payload y lo puede reenviar a:

- Chatwoot API.
- n8n webhook.
- Supabase REST/RPC.

La activacion de cada destino se controla por variables de entorno.

## Politica de licencia y marca

Este repo evita automatizar desbloqueos, bypasses de licencia o reemplazos de marca no verificables. Si se usa una imagen custom de Chatwoot entregada por el proveedor o construida bajo licencia, configurala con `CHATWOOT_IMAGE`.

## Validacion local

```bash
docker compose --env-file .env.example config
python3 scripts/check-env-example.py
```
