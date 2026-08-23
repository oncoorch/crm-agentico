#!/usr/bin/env python3
from pathlib import Path


required = {
    "CRM_PUBLIC_URL",
    "N8N_PUBLIC_URL",
    "EVOLUTION_PUBLIC_URL",
    "MCP_PUBLIC_URL",
    "CHATWOOT_POSTGRES_PASSWORD",
    "CHATWOOT_REDIS_PASSWORD",
    "CHATWOOT_SECRET_KEY_BASE",
    "N8N_POSTGRES_PASSWORD",
    "N8N_REDIS_PASSWORD",
    "N8N_ENCRYPTION_KEY",
    "EVOLUTION_API_KEY",
    "EVOLUTION_POSTGRES_PASSWORD",
    "MCP_SHARED_SECRET",
}


def main() -> int:
    env_path = Path(".env.example")
    values: dict[str, str] = {}
    for line in env_path.read_text().splitlines():
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key] = value

    missing = sorted(required - values.keys())
    if missing:
        print("Missing required keys:")
        for key in missing:
            print(f"- {key}")
        return 1

    suspicious = []
    for key, value in values.items():
        upper = key.upper()
        if any(marker in upper for marker in ("SECRET", "PASSWORD", "TOKEN", "KEY")):
            if value and value not in {"change_me", "true", "false"} and not value.startswith("change_me"):
                suspicious.append(key)

    if suspicious:
        print("Suspicious non-placeholder secret values in .env.example:")
        for key in suspicious:
            print(f"- {key}")
        return 1

    print("env example ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
