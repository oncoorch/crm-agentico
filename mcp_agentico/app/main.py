import os
from typing import Any

import httpx
from fastapi import FastAPI, Header, HTTPException, Request
from pydantic import BaseModel, Field


app = FastAPI(title="CRM Agentico Bridge", version="0.1.0")


class LeadPayload(BaseModel):
    name: str | None = None
    email: str | None = None
    phone: str | None = None
    source: str = "website"
    message: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)


def env(name: str, default: str = "") -> str:
    return os.getenv(name, default).strip()


def require_shared_secret(x_crm_secret: str | None) -> None:
    expected = env("MCP_SHARED_SECRET")
    if expected and x_crm_secret != expected:
        raise HTTPException(status_code=401, detail="invalid_secret")


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/leads")
async def receive_lead(
    payload: LeadPayload,
    request: Request,
    x_crm_secret: str | None = Header(default=None),
) -> dict[str, Any]:
    require_shared_secret(x_crm_secret)

    lead = payload.model_dump()
    lead["client_ip"] = request.headers.get("cf-connecting-ip") or request.client.host if request.client else None

    results: dict[str, Any] = {}
    async with httpx.AsyncClient(timeout=20) as client:
        if chatwoot_enabled():
            results["chatwoot"] = await create_chatwoot_contact(client, lead)
        if env("N8N_LEAD_WEBHOOK_URL"):
            results["n8n"] = await post_json(client, env("N8N_LEAD_WEBHOOK_URL"), lead)
        if env("SUPABASE_URL") and env("SUPABASE_SERVICE_ROLE_KEY"):
            table = env("SUPABASE_LEADS_TABLE", "leads")
            url = f"{env('SUPABASE_URL').rstrip('/')}/rest/v1/{table}"
            headers = {
                "apikey": env("SUPABASE_SERVICE_ROLE_KEY"),
                "authorization": f"Bearer {env('SUPABASE_SERVICE_ROLE_KEY')}",
                "content-type": "application/json",
                "prefer": "return=minimal",
            }
            results["supabase"] = await post_json(client, url, lead, headers=headers)

    return {"ok": True, "routes": results}


def chatwoot_enabled() -> bool:
    return all(
        [
            env("CHATWOOT_BASE_URL"),
            env("CHATWOOT_API_ACCESS_TOKEN"),
            env("CHATWOOT_ACCOUNT_ID"),
        ]
    )


async def create_chatwoot_contact(client: httpx.AsyncClient, lead: dict[str, Any]) -> dict[str, Any]:
    account_id = env("CHATWOOT_ACCOUNT_ID", "1")
    url = f"{env('CHATWOOT_BASE_URL').rstrip('/')}/api/v1/accounts/{account_id}/contacts"
    payload = {
        "name": lead.get("name") or lead.get("email") or lead.get("phone") or "Lead sin nombre",
        "email": lead.get("email"),
        "phone_number": lead.get("phone"),
        "identifier": lead.get("email") or lead.get("phone"),
        "custom_attributes": {
            "source": lead.get("source"),
            "message": lead.get("message"),
            "client_ip": lead.get("client_ip"),
            **(lead.get("metadata") or {}),
        },
    }
    payload = {key: value for key, value in payload.items() if value}
    headers = {"api_access_token": env("CHATWOOT_API_ACCESS_TOKEN")}
    return await post_json(client, url, payload, headers=headers)


async def post_json(
    client: httpx.AsyncClient,
    url: str,
    payload: dict[str, Any],
    headers: dict[str, str] | None = None,
) -> dict[str, Any]:
    try:
        response = await client.post(url, json=payload, headers=headers)
        return {"status_code": response.status_code, "ok": response.is_success}
    except Exception as exc:
        return {"ok": False, "error": exc.__class__.__name__}
