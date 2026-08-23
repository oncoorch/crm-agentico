# Operaciones de host

Estos comandos se ejecutan por SSH en el VPS, no dentro del contenedor.

## Instalar wrappers en `/opt`

Desde una copia del repositorio:

```bash
cd /opt/crm-agentico
sudo scripts/install_host_ops.sh
source /opt/crm-agentico/bin/env
```

Esto crea:

```text
/opt/crm-agentico/bin/crm-komodo-config-sync
/opt/crm-agentico/bin/crm-komodo-branding-apply
/opt/crm-agentico/bin/n8n-seed-credentials-build
/opt/crm-agentico/bin/n8n-export-seed-commit
/opt/crm-agentico/bin/install-n8n-daily-git-backup
```

## `build_n8n_seed_credentials_bundle.py`

Genera el valor secreto para Dokploy:

```bash
cd /opt/crm-agentico
python3 scripts/build_n8n_seed_credentials_bundle.py \
  --credentials-dir /ruta/a/credentials-flat
```

Salida:

```text
private/n8n-seed/N8N_SEED_CREDENTIALS_TGZ_B64.txt
```

El contenido de ese archivo se pega en Dokploy como:

```text
N8N_SEED_CREDENTIALS_TGZ_B64=<contenido>
```

## `chatwoot_config_sync.sh`

Sincroniza nombre e URLs publicas de Chatwoot:

```bash
cd /opt/crm-agentico
CHATWOOT_BRAND_NAME="CRM-Komodo" \
CHATWOOT_INSTALLATION_NAME="CRM-Komodo" \
CHATWOOT_BRAND_URL="https://crm.oncoorch.com" \
CHATWOOT_WIDGET_BRAND_URL="https://crm.oncoorch.com" \
scripts/chatwoot_config_sync.sh
```

Wrapper corto:

```bash
/opt/crm-agentico/bin/crm-komodo-config-sync
```

## `chatwoot_branding_assets.sh`

Aplica imagenes desde `/opt/crm_branding` al contenedor Chatwoot. Tambien
aplica el parche visual de SuperAdmin: fondo de login, favicon, saludo y textos
basicos de acceso.

```bash
sudo mkdir -p /opt/crm_branding
cd /opt/crm-agentico
CHATWOOT_BRANDING_SOURCE_DIR=/opt/crm_branding scripts/chatwoot_branding_assets.sh
```

Wrapper corto:

```bash
/opt/crm-agentico/bin/crm-komodo-branding-apply
```

## `chatwoot_superadmin_ui_patch.sh`

Parche posdeploy para la interfaz Rails de SuperAdmin. Normalmente se ejecuta
desde `chatwoot_branding_assets.sh`; usalo directamente solo si quieres reaplicar
el login sin volver a copiar imagenes.

```bash
cd /opt/crm-agentico
scripts/chatwoot_superadmin_ui_patch.sh
```

## Respaldo diario de workflows n8n hacia GitHub

Para evitar perder workflows creados desde la interfaz de n8n:

```bash
/opt/crm-agentico/bin/n8n-export-seed-commit
```

Si hay cambios, exporta workflows, los sanea, actualiza `n8n-seed/workflows`, crea commit y hace push.

Para dejarlo diario a las 03:17:

```bash
/opt/crm-agentico/bin/install-n8n-daily-git-backup
```

Requisito: el VPS debe tener permisos Git para hacer `git push` al repositorio.
