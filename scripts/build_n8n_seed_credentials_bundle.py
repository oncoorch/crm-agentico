#!/usr/bin/env python3
"""Build a local base64 credential bundle for Dokploy.

The output contains real n8n credential JSON files. It is intentionally written
under private/ and must be copied into Dokploy as a secret environment variable,
not committed to Git.
"""

from __future__ import annotations

import argparse
import base64
import shutil
import tarfile
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--credentials-dir",
        default="private/n8n-seed/source-credentials",
        help="Directory containing decrypted n8n credential JSON files.",
    )
    parser.add_argument("--out-dir", default="private/n8n-seed")
    args = parser.parse_args()

    source = Path(args.credentials_dir)
    out_dir = Path(args.out_dir)
    if not source.is_dir():
        raise SystemExit(f"Missing credentials directory: {source}")

    out_dir.mkdir(parents=True, exist_ok=True)
    archive = out_dir / "n8n-seed-credentials.tar.gz"
    b64_file = out_dir / "N8N_SEED_CREDENTIALS_TGZ_B64.txt"

    if archive.exists():
        archive.unlink()
    with tarfile.open(archive, "w:gz") as tar:
        for path in sorted(source.glob("*.json")):
            tar.add(path, arcname=path.name)

    b64_file.write_text(base64.b64encode(archive.read_bytes()).decode("ascii"), encoding="utf-8")
    print(f"Archive: {archive}")
    print(f"Dokploy variable file: {b64_file}")
    print(f"Credentials: {len(list(source.glob('*.json')))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
