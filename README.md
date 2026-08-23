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
- `prompt_manager`: editor web seguro para system prompts de agentes n8n.
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
   - `prompter.oncoorch.com` -> servicio `prompt_manager`, puerto `3100`.
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

- Chatwoot: configurar `CHATWOOT_BASE_URL`, `CHATWOOT_ACCOUNT_ID` y `CHATWOOT_API_ACCESS_TOKEN`.
- n8n: configurar `N8N_LEAD_WEBHOOK_URL`.
- Supabase: configurar `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` y `SUPABASE_LEADS_TABLE`.

Todas las llamadas al bridge deben enviar el header `x-crm-secret` con el valor de `MCP_SHARED_SECRET`.

## Operacion y respaldo

Este repositorio incluye scripts para operar VPS nuevos con la misma base madura observada en los laboratorios:

- `scripts/chatwoot_config_sync.sh`: sincroniza nombre publico, URLs y parametros visibles de Chatwoot desde variables de entorno.
- `docker/chatwoot/Dockerfile`: construye la imagen `CRM-Komodo` desde la imagen base de Chatwoot, copiando branding y parcheando el login de SuperAdmin durante el build.
- `scripts/chatwoot_branding_assets.sh`: aplica imagenes e iconos autorizados desde `branding/chatwoot/public` al VPS actual.
- `scripts/install_maintenance_cron.sh`: instala las tareas periodicas en el servidor.
- `scripts/n8n_export_backup.sh`: exporta workflows y credenciales de n8n a `private/n8n-backups`.
- `scripts/n8n_seed_import.sh`: importa automaticamente workflows y credenciales semilla en n8n durante el despliegue.

Para instalar las tareas periodicas en un VPS ya desplegado:

```bash
sudo scripts/install_maintenance_cron.sh
```

Para respaldar n8n desde el servidor:

```bash
scripts/n8n_export_backup.sh
```

Los respaldos y secretos reales deben quedar bajo `private/`, que esta excluida de Git.

## Documentacion

- `docs/dokploy-runbook.md`: despliegue en Dokploy.
- `docs/mcp-connector.md`: uso e implementacion del conector MCP Agentico.
- `docs/n8n-seed.md`: importacion reproducible de workflows y credenciales n8n desde GitHub/Dokploy.
- `docs/host-operations.md`: scripts para ejecutar branding, config y respaldos desde el VPS.
- `docs/prompt-manager.md`: uso, variables y despliegue de Prompt Manager.
- `docs/source-vps-inventory.md`: VPS usados como referencia de arquitectura.
- `CONTEXTO_GPT.md`: resumen para continuar el trabajo en futuras conversaciones.

## Politica de licencia y marca

Este repo evita automatizar desbloqueos, bypasses de licencia o reemplazos de marca no verificables. Si se usa una imagen custom de Chatwoot entregada por el proveedor o construida bajo licencia, configurala como `CHATWOOT_IMAGE`; el runtime final se construye como `CHATWOOT_RUNTIME_IMAGE`.

Evolution API usa por defecto `EVOLUTION_IMAGE=evoapicloud/evolution-api:v2.2.3`, reemplazando la ruta historica `atendai/evolution-api:v2.2.3`.

## Validacion local

```bash
docker compose --env-file .env.example config
python3 scripts/check-env-example.py
```
