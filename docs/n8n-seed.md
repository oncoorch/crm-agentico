# Semilla n8n desde GitHub

El stack importa workflows y credenciales en n8n mediante el servicio `n8n_seed` definido en `compose.yml`.

## Que queda versionado

- `n8n-seed/workflows/`: 203 workflows renombrados como `name_hostname`.
- `scripts/n8n_seed_import.sh`: importador ejecutado por el servicio `n8n_seed`.
- `scripts/n8n_seed_assign_folders.js`: crea carpetas por VPS y asigna workflows por sufijo.
- `scripts/build_n8n_seed_credentials_bundle.py`: generador local del paquete secreto de credenciales.

Los workflows quedan inactivos (`active=false`) para evitar ejecuciones accidentales despues de un despliegue. Tambien se eliminaron `pinData/staticData` y valores sensibles hardcodeados; cualquier secreto debe vivir como credencial n8n o variable de entorno.

## Que no queda versionado

Las credenciales reales de n8n no se guardan en GitHub. Se cargan desde la variable secreta:

```text
N8N_SEED_CREDENTIALS_TGZ_B64
```

El valor se genera localmente:

```bash
python3 scripts/build_n8n_seed_credentials_bundle.py
```

Si las credenciales fuente estan fuera del repo, indicar la ruta:

```bash
python3 scripts/build_n8n_seed_credentials_bundle.py \
  --credentials-dir /ruta/a/credentials-flat
```

El archivo resultante queda en:

```text
private/n8n-seed/N8N_SEED_CREDENTIALS_TGZ_B64.txt
```

Ese contenido debe pegarse en Dokploy como variable de entorno del servicio Compose.

## Variables

| Variable | Uso |
|---|---|
| `N8N_SEED_CREDENTIALS_TGZ_B64` | Credenciales n8n comprimidas/base64 |
| `N8N_SEED_PROJECT_ID` | Proyecto n8n destino; para el n8n actual es `Wxcc72mwXx2dIsJU` |
| `N8N_SEED_IMPORT_CREDENTIALS` | `true` para importar credenciales |
| `N8N_SEED_IMPORT_WORKFLOWS` | `true` para importar workflows |
| `N8N_SEED_ASSIGN_FOLDERS` | `true` para crear/asignar carpetas por VPS |

Si `N8N_SEED_PROJECT_ID` queda vacio, n8n usa el comportamiento por defecto del CLI. Para mantener todo dentro del proyecto `Personal`, usa el ID del proyecto visible en la URL de n8n.

## Flujo en Dokploy

1. Dokploy clona `oncoorch/crm-agentico`.
2. Levanta `n8n_postgres`.
3. Levanta `n8n`.
4. Ejecuta `n8n_seed`.
5. `n8n_seed` espera la base de datos, importa credenciales, importa workflows y asigna carpetas por VPS.

Los IDs de workflows son estables, por lo que un redeploy actualiza la semilla en vez de depender de cambios manuales hechos dentro del contenedor.

## Conteo de semilla

- Workflows: 203
- Credenciales esperadas en el paquete secreto: 99

## Verificacion

En n8n deben aparecer carpetas y workflows con nombres como:

```text
VoiceDesk - Clients_armacar
Agente Hyundai - PROD_hyundai
Chat Kay_kia-electrolineras
```
