# CONTEXTO GPT - CRM Agentico

Este archivo permite continuar el trabajo en otra conversacion.

## Repositorio

- Repo: `https://github.com/oncoorch/crm-agentico`
- Proposito: stack Dokploy para CRM agentico basado en la arquitectura Aigents madura observada en VPS de laboratorio.

## Estado actual

- Compose principal: `compose.yml`.
- Servicios: Chatwoot, Sidekiq, PostgreSQL/pgvector, Redis, n8n, Evolution API, MCP Agentico, Prompt Manager.
- Dokploy NICOP ya tiene un proyecto conectado a `main` con auto deploy.
- Dominios usados en la primera instalacion:
  - `crm.oncoorch.com`
  - `automation-crm.oncoorch.com`
  - `evolution.oncoorch.com`
  - `crm-agent.oncoorch.com`
  - `prompter.oncoorch.com` o dominio equivalente para Prompt Manager

## Referencias de arquitectura

- Repo documental: `https://github.com/oncoorch/aigents_vps`
- VPS referencia principal: Hyundai (`154.38.191.168`).
- VPS referencia compacta: 1001talleres (`147.93.179.212`).

## Scripts agregados

- `docker/chatwoot/Dockerfile`: construye la imagen marcada `CRM-Komodo` desde `CHATWOOT_IMAGE`, copiando assets y parcheando el login de SuperAdmin durante build.
- `scripts/chatwoot_config_sync.sh`: sincroniza nombre, URLs y configuraciones publicas autorizadas de Chatwoot.
- `scripts/chatwoot_branding_assets.sh`: copia assets de marca autorizados al contenedor Chatwoot.
- `scripts/install_maintenance_cron.sh`: instala cron para sync/branding.
- `scripts/n8n_export_backup.sh`: exporta workflows y credenciales n8n a una carpeta privada local del servidor.
- `scripts/n8n_seed_import.sh`: corre dentro del servicio `n8n_seed` para importar workflows/credenciales en cada despliegue.
- `scripts/n8n_seed_resolve_project.js`: detecta automaticamente el proyecto Personal de n8n.
- `scripts/n8n_seed_assign_folders.js`: crea/asigna carpetas por VPS.
- `scripts/build_n8n_seed_credentials_bundle.py`: genera localmente `private/n8n-seed/N8N_SEED_CREDENTIALS_TGZ_B64.txt`.
- `prompt-manager/`: aplicacion Next.js para editar prompts desde UI con login, preview Markdown y auditoria.

## Manuales

- `docs/mcp-connector.md`: funcionamiento e implementacion del conector MCP.
- `docs/n8n-seed.md`: semilla reproducible de workflows y credenciales n8n.
- `docs/host-operations.md`: uso de wrappers instalables en `/opt/crm-agentico/bin`.
- `docs/dokploy-runbook.md`: despliegue Dokploy.
- `docs/source-vps-inventory.md`: origen de la arquitectura.
- `docs/prompt-manager.md`: uso y despliegue de Prompt Manager.

## Prompt Manager

- Servicio compose: `prompt_manager`, puerto interno `3100`.
- Dominio sugerido: `prompter.oncoorch.com`.
- Lee workflows/nodos desde `n8n_postgres.workflow_entity`.
- Lista solo prompts registrados en `n8n_postgres.public.agent_prompts`.
- Prompt activo de KomodoBot: `waba_system_promt`, workflow `61fvbcCLHObsy3Tm`, nodo `System Promt`, Redis DB `1`.
- Guarda el prompt estable en `agent_prompts`, sincroniza Redis `n8n_redis` como cache runtime y mantiene `public.parameters` por compatibilidad con el workflow.
- Registra auditoria en `n8n_postgres.public.prompt_manager_audit`.
- Usuarios por variable `PROMPT_MANAGER_USERS_B64`, generada con `prompt-manager/scripts/create-users.mjs`.

## Semilla n8n

- `n8n-seed/workflows/`: 203 workflows renombrados como `name_hostname`.
- Las credenciales reales no se suben a GitHub; se pasan por la variable secreta `N8N_SEED_CREDENTIALS_TGZ_B64`.
- Para el n8n actual de `automation-crm.oncoorch.com`, el proyecto Personal observado es `Wxcc72mwXx2dIsJU`; el seed puede autodetectarlo si `N8N_SEED_PROJECT_ID` esta vacio.

## Operacion desde VPS

- `scripts/install_host_ops.sh` instala wrappers en `/opt/crm-agentico/bin`.
- `/opt/crm-agentico/bin/crm-komodo-config-sync` aplica nombre `CRM-Komodo`.
- `/opt/crm-agentico/bin/crm-komodo-branding-apply` copia assets desde `/opt/crm_branding`.
- `/opt/crm-agentico/bin/n8n-export-seed-commit` exporta workflows desde n8n vivo, sanea JSON y hace commit/push.

## Linea de seguridad

- No guardar `.env` reales ni backups privados en GitHub.
- Usar `CHATWOOT_IMAGE` para imagen base autorizada/custom. El compose construye `CHATWOOT_RUNTIME_IMAGE` con branding y login parcheado.
- Scripts de branding/config sync son parametrizables y no modifican plan/licencia.

## Siguiente paso natural

1. Revisar variables actuales de Dokploy.
2. Si se desea, activar cron de mantenimiento en el VPS NICOP.
3. Agregar modulos MCP avanzados segun necesidades: agenda, catalogo, sedes, estado conversacional y flujos WhatsApp.
4. Desplegar en Dokploy cuando la version del repo este aprobada.
