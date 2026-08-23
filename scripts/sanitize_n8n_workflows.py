#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import shutil
import uuid
from pathlib import Path


SENSITIVE_KEY = re.compile(
    r"(^|[_-])(api[-_]?key|apikey|authorization|access[-_]?token|refresh[-_]?token|id[-_]?token|client[-_]?secret|secret|password|passwd|pwd|private[-_]?key|jwt[-_]?secret)([_-]|$)",
    re.I,
)
PATTERNS = [
    (re.compile(r"(Bearer\s+)[A-Za-z0-9._~+/=-]{16,}", re.I), r"\1${REDACTED_TOKEN}"),
    (
        re.compile(
            r"((?:JWT_SECRET|CLIENT_SECRET|API_KEY|ACCESS_TOKEN|REFRESH_TOKEN|PRIVATE_KEY|PASSWORD)\s*=\s*[\"'])(.*?)([\"'])",
            re.I,
        ),
        r"\1${REDACTED_SECRET}\3",
    ),
    (
        re.compile(
            r"(\"(?:api-key|apikey|x-api-key|authorization|access_token|refresh_token|client_secret|password|secret)\"\s*:\s*\")(.*?)(\")",
            re.I,
        ),
        r"\1${REDACTED_SECRET}\3",
    ),
    (
        re.compile(r"((?:api[-_]?key|apikey|access_token|refresh_token|client_secret|password|secret)=)[^&\s\"']+", re.I),
        r"\1${REDACTED_SECRET}",
    ),
    (re.compile(r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"), "${REDACTED_JWT}"),
]


def safe_filename(text: str) -> str:
    text = re.sub(r'[\\/:*?"<>|]+', "-", text).strip().rstrip(".")
    text = re.sub(r"\s+", " ", text)
    return text[:160] or "workflow"


def sanitize_string(value: str) -> str:
    for pattern, replacement in PATTERNS:
        value = pattern.sub(replacement, value)
    return value


def sanitize(value):
    if isinstance(value, dict):
        return {
            key: ("${REDACTED_SECRET}" if SENSITIVE_KEY.search(str(key)) else sanitize(item))
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [sanitize(item) for item in value]
    if isinstance(value, str):
        return sanitize_string(value)
    return value


def normalize_workflow(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    workflow_id = str(data.get("id") or path.stem)
    return {
        "id": workflow_id,
        "name": data.get("name") or workflow_id,
        "nodes": sanitize(data.get("nodes") or []),
        "connections": data.get("connections") or {},
        "settings": sanitize(data.get("settings") or {}),
        "pinData": {},
        "active": False,
        "versionId": data.get("versionId") or str(uuid.uuid5(uuid.NAMESPACE_URL, f"oncoorch/crm-agentico/n8n/{workflow_id}")),
        "versionCounter": 1,
        "triggerCount": 0,
        "isArchived": False,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-dir", required=True)
    parser.add_argument("--output-dir", default="n8n-seed/workflows")
    parser.add_argument("--replace", action="store_true")
    args = parser.parse_args()

    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir)
    if not input_dir.is_dir():
        raise SystemExit(f"Missing input directory: {input_dir}")

    if args.replace and output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    for path in sorted(input_dir.rglob("*.json")):
        workflow = normalize_workflow(path)
        out = output_dir / f"{safe_filename(workflow['name'])}.json"
        suffix = 2
        while out.exists():
            out = output_dir / f"{safe_filename(workflow['name'])} ({suffix}).json"
            suffix += 1
        out.write_text(json.dumps(workflow, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        count += 1

    print(f"Sanitized workflows: {count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
