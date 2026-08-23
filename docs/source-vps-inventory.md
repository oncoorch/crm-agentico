# Inventario de VPS fuente

Fecha de inspeccion: 2026-08-23.

## VPS 217.216.89.91

Host: `cloud-aigentss-9round-cr`

Estado observado:

- Solo estaban corriendo `app_proxy` y `db_proxy`.
- Existe `/opt/aigentss` con compose historicos para:
  - Nginx Proxy Manager.
  - Portainer.
  - Chatwoot/Chatwood.
  - n8n.
  - Redis.
  - Evolution API.
  - Adminer.
  - Supabase.
  - MCP.
- Se detectaron secretos hardcodeados en compose/env historicos. No se copiaron al repo.

## VPS 154.38.191.168

Host: `cloud-aigentss-hyundai`

Estado observado:

- Stack activo con Docker Compose:
  - `chatwoot` y `chatwoot_sidekiq`.
  - `chatwoot_postgres`.
  - `chatwoot_redis`.
  - `n8n`, `n8n_postgres`, `n8n_redis`.
  - `supabase-*`.
  - `mcp_server_prod` y `mcp_server`.
  - `evolution` dependiente de Postgres/Redis.
  - `app_proxy`/`db_proxy`.
- Chatwoot usa imagen custom:
  - `omnicem/chatwoot:reports-c0b1b1c3e`
  - Compose real: `/opt/omnicem-chatwoot/deployment/docker-compose.vps.yml`
- MCP productivo usa variables de entorno para:
  - Base app/Supabase.
  - Base Chatwoot.
  - Chatwoot API token.
  - SGC externo.
  - Firma de webhooks/flows.

## Decisiones para este repo

- No copiar `.env`, secretos, llaves privadas ni dumps.
- No automatizar parches de licencia/desbloqueo ni reemplazos de marca no verificables.
- Permitir `CHATWOOT_IMAGE` para usar una imagen autorizada por la organizacion.
- Usar redes internas y exponer solo servicios por Dokploy/Traefik.
- Mantener el bridge `mcp_agentico` como codigo propio y parametrizado.
