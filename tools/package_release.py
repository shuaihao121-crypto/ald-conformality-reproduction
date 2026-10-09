#!/usr/bin/env python3
"""Validate and create a reproducible source release; standard library only."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import zipfile


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def release_files(root: Path) -> list[Path]:
    excluded = {".git", "results", "__pycache__", "private"}
    return sorted(
        path for path in root.rglob("*")
        if path.is_file()
        and not any(part in excluded for part in path.relative_to(root).parts)
        and path.suffix.lower() not in {".pyc", ".asv", ".zip"}
        and not path.name.startswith(".env")
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    output = (args.output_dir or root.parent).resolve()
    if output == root or root in output.parents:
        parser.error("Choose an output directory outside the repository.")
    subprocess.run(
        [sys.executable, str(root / "checks/validate_repository.py")],
        cwd=root, check=True,
    )
    manifest_path = root / "data/release_manifest.json"
    entries = [
        {"path": str(path.relative_to(root)).replace("\\", "/"),
         "bytes": path.stat().st_size, "sha256": sha256(path)}
        for path in release_files(root) if path != manifest_path
    ]
    manifest_path.write_text(
        json.dumps({"schema_version": 1, "version": "0.1.0",
                    "release_date": "2026-10-09",
                    "policy": "Source archive; generated runs and private material excluded. Manifest does not hash itself.",
                    "file_count": len(entries), "files": entries},
                   ensure_ascii=False, indent=2) + "\n", encoding="utf-8",
    )
    output.mkdir(parents=True, exist_ok=True)
    archive = output / "ald-conformality-reproduction-v0.1.0.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED,
                         compresslevel=9) as zf:
        for path in release_files(root):
            name = f"{root.name}/{path.relative_to(root).as_posix()}"
            entry = zipfile.ZipInfo(name, date_time=(2026, 10, 9, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            zf.writestr(entry, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED,
                        compresslevel=9)
    checksum = archive.with_suffix(archive.suffix + ".sha256")
    checksum.write_text(f"{sha256(archive)}  {archive.name}\n", encoding="ascii")
    with zipfile.ZipFile(archive) as zf:
        bad = zf.testzip()
        if bad:
            raise RuntimeError(f"ZIP integrity failure: {bad}")
    print(f"Created {archive.name}: {archive.stat().st_size:,} bytes")
    print(f"SHA-256: {sha256(archive)}")


if __name__ == "__main__":
    main()
