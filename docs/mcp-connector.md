# Conector MCP Agentico

El conector MCP es el servicio Python/FastAPI que recibe leads, expone herramientas internas y conecta n8n con Chatwoot, Supabase y otros servicios del stack.

## Responsabilidad

- Recibir leads normalizados desde web, n8n o canales externos.
- Crear o actualizar contactos en Chatwoot cuando existe `CHATWOOT_API_ACCESS_TOKEN`.
- Reenviar payloads a n8n mediante `N8N_LEAD_WEBHOOK_URL`.
- Persistir leads en Supabase cuando existen `SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY`.
- Servir como base para herramientas adicionales de inventario, agenda, productos, sedes y estado conversacional.

## Endpoints actuales

| Endpoint | Metodo | Uso |
|---|---|---|
| `/healthz` | GET | Health check |
| `/leads` | POST | Entrada de leads |

## Seguridad

Todas las llamadas a `/leads` deben enviar:

```text
x-crm-secret: <MCP_SHARED_SECRET>
```

## Payload de lead

```json
{
  "name": "Nombre",
  "email": "lead@example.com",
  "phone": "+593...",
  "source": "website",
  "message": "Mensaje",
  "metadata": {
    "campaign": "demo"
  }
}
```

## Variables

| Variable | Requerida | Uso |
|---|---|---|
| `MCP_SHARED_SECRET` | Si | Header compartido |
| `CHATWOOT_BASE_URL` | No | URL interna de Chatwoot |
| `CHATWOOT_API_ACCESS_TOKEN` | No | Token para contactos |
| `CHATWOOT_ACCOUNT_ID` | No | Cuenta Chatwoot |
| `N8N_LEAD_WEBHOOK_URL` | No | Webhook de n8n |
| `SUPABASE_URL` | No | REST Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | No | Service role |
| `SUPABASE_LEADS_TABLE` | No | Tabla destino |

## Implementacion en VPS nuevo

1. Completar `.env` desde `.env.example`.
2. Levantar el compose.
3. Verificar:

```bash
curl https://crm-agent.<dominio>/healthz
```

4. Probar lead:

```bash
curl -X POST https://crm-agent.<dominio>/leads \
  -H 'content-type: application/json' \
  -H "x-crm-secret: $MCP_SHARED_SECRET" \
  --data '{"name":"Lead Demo","source":"manual"}'
```

## Extension

Para acercarlo a los VPS maduros, agregar modulos bajo `mcp_agentico/app/`:

- `chatwoot.py`: funciones CRM.
- `appointments.py`: agenda.
- `products.py`: catalogo.
- `establishments.py`: sedes.
- `conversation_state.py`: estado conversacional.
- `flow_endpoint.py`: flujos Meta/WhatsApp.
