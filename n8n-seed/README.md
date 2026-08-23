# n8n Seed

Esta carpeta contiene workflows versionados para importar automaticamente en el n8n del stack.

- `workflows/`: workflows sin credenciales embebidas, renombrados como `name_hostname`.
- Las credenciales reales no se guardan en Git. Se importan desde la variable secreta `N8N_SEED_CREDENTIALS_TGZ_B64`.

El servicio `n8n_seed` del `compose.yml` ejecuta `scripts/n8n_seed_import.sh` contra la misma base de datos de n8n.
