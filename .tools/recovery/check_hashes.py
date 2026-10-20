#!/usr/bin/env python3
"""Registra las huellas sha256 y el tamaño de las fuentes y del APK.

Uso:  check_hashes.py <apk> <glb> [más archivos...]
"""
from __future__ import annotations

import hashlib
import json
import sys
from datetime import datetime
from pathlib import Path

SALIDA = Path(".tools/recovery/integral/huellas.json")


def main() -> int:
    paths = [Path(argument) for argument in sys.argv[1:]]
    paths.append(Path("assets/RedBull-Drive.glb"))
    data = {}
    for path in paths:
        if not path.is_file():
            print("falta", path)
            return 1
        data[str(path)] = {
            "bytes": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "mtime": datetime.fromtimestamp(path.stat().st_mtime).isoformat(timespec="seconds"),
        }
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    SALIDA.write_text(json.dumps(data, indent=2, ensure_ascii=False))
    for path, info in data.items():
        print("%-42s %12d  %s  %s" % (path, info["bytes"], info["sha256"][:16], info["mtime"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
