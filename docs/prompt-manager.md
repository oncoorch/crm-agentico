# Prompt Manager

Prompt Manager es la interfaz interna para editar system prompts usados por agentes n8n sin entrar manualmente a Redis o Postgres.

## URL sugerida

```text
https://prompter.oncoorch.com
```

En Dokploy, crear un dominio apuntando al servicio `prompt_manager`, puerto `3100`.

## Variables requeridas

```env
PROMPT_MANAGER_PUBLIC_URL=https://prompter.oncoorch.com
PROMPT_MANAGER_SESSION_SECRET=change_me
PROMPT_MANAGER_USERS_B64=change_me_users_b64
PROMPT_MANAGER_REDIS_DB=1
```

`PROMPT_MANAGER_SESSION_SECRET` debe ser un secreto largo:

```bash
openssl rand -base64 48 | tr -d '\n'
```

`PROMPT_MANAGER_USERS_B64` se genera con:

```bash
cd prompt-manager
npm install
node scripts/create-users.mjs angel:PasswordSeguro:superadmin jairo:PasswordSeguro:editor operador:PasswordSeguro:editor
```

El comando imprime una cadena base64. Esa cadena completa se pega en Dokploy como `PROMPT_MANAGER_USERS_B64`.

## Uso

1. Iniciar sesión.
2. Elegir un `Prompt registrado`.
3. Confirmar `Workflow Name`, `Node Name` y `Redis DB`.
4. Usar `Cargar` para traer el prompt desde el registro estable.
6. Editar el Markdown en la columna izquierda.
7. Revisar el preview enriquecido en la columna derecha.
8. Usar `Guardar Cambios`.

Cada guardado:

- Actualiza `public.agent_prompts` como fuente estable.
- Sincroniza Redis en la DB configurada, por defecto `1`, solo como cache runtime.
- Actualiza `public.parameters` en `n8n_postgres` por compatibilidad con workflows existentes.
- Registra auditoría en `public.prompt_manager_audit`.

## Registro estable

Los prompts editables viven en `n8n_postgres.public.agent_prompts`. Esta tabla evita perder prompts cuando se limpia Redis para borrar cache de conversaciones. El workflow `KomodoBot` usa actualmente:

```text
key: waba_system_promt
workflow_id: 61fvbcCLHObsy3Tm
workflow_name: KomodoBot
node_name: System Promt
redis_db: 1
```

## Auditoría

La app guarda:

- usuario que cambió el prompt;
- workflow y nodo seleccionados;
- parameter key;
- Redis DB;
- hash anterior y nuevo;
- longitud anterior y nueva;
- fecha/hora del cambio.

No guarda copias históricas completas del prompt para evitar duplicar contenido sensible; si se requiere versionado completo, debe respaldarse desde Git o extender la tabla de auditoría.
