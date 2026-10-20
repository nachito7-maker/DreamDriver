#!/usr/bin/env python3
"""Construye el informe JSON de la verificación integral y la tabla de salida."""
from __future__ import annotations

import hashlib
import json
import sys
from datetime import datetime
from pathlib import Path

EXTRAS = ("huellas.json", "shots/toque/touch.json")
DIAGNOSTICS = {
    "dispositivo": "logs/dispositivo.log",
    "instalar": "logs/instalar.log",
    "huella_instalada": "logs/huella_instalada.log",
    "toque": "logs/toque.log",
}


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> int:
    out = Path(sys.argv[1])
    checks = []
    for line in (out / "checks.tsv").read_text().splitlines():
        if line.strip():
            identifier, status, seconds, mandatory, description = line.split("\t")
            checks.append({"id": identifier, "estado": status, "segundos": int(seconds),
                           "obligatoria": mandatory == "si", "descripcion": description})

    extras = {}
    for name in EXTRAS:
        path = out / name
        if path.is_file():
            extras[path.stem] = json.loads(path.read_text())
    for path in (Path(".tools/recovery/pbr/track_material_audit.json"),
                 Path(".tools/recovery/artifact_audit.json"),
                 Path(".tools/recovery/conversion_report.json")):
        if path.is_file():
            extras[path.stem] = json.loads(path.read_text())

    failures = [c["id"] for c in checks if c["obligatoria"] and c["estado"] == "fallo"]
    omitted = [c["id"] for c in checks if c["estado"] == "omitida"]
    retest_path = Path(".tools/recovery/final-retest.json")
    retest = json.loads(retest_path.read_text()) if retest_path.is_file() else None
    report = {
        "fecha": datetime.now().isoformat(timespec="seconds"),
        "comprobaciones": checks,
        "fallos_obligatorios": failures,
        "omitidas": omitted,
        "extras": extras,
        "resultado": "FALLO" if failures else ("PARCIAL" if omitted else "OK"),
        "revalidacion_independiente": retest,
    }
    (out / "verificacion-integral.json").write_text(json.dumps(report, indent=2, ensure_ascii=False))

    apk = Path("build/android/F1OneShot-BarcelonaMoto.apk")
    apk_info = {"path": str(apk), "bytes": apk.stat().st_size, "sha256": file_hash(apk)} if apk.is_file() else {"path": str(apk), "missing": True}
    installed = out / "base-instalada.apk"
    if installed.is_file() and apk.is_file():
        installed_hash = file_hash(installed)
        apk_info["installed"] = {"path": str(installed), "bytes": installed.stat().st_size,
                                 "sha256": installed_hash, "matches": installed_hash == apk_info["sha256"]}

    display = {}
    for name in ("pantalla.png", "pantalla-final.png", "final-hash-screen.png", "final-hash-screen-after.png"):
        image_path = out / "shots" / name
        if image_path.is_file():
            from PIL import Image
            image = Image.open(image_path)
            display[name] = {"width": image.width, "height": image.height}
    diagnostics = {}
    for identifier in failures:
        relative = DIAGNOSTICS.get(identifier)
        if relative and (out / relative).is_file():
            diagnostics[identifier] = (out / relative).read_text(errors="replace")[-1600:].strip()

    touch_path = Path(".tools/recovery/integral/shots/toque-hash-final/touch.json")
    touch_retest = json.loads(touch_path.read_text()) if touch_path.is_file() else {}
    touch = extras.get("touch", {})
    touch_check = next((c for c in checks if c["id"] == "toque"), None)
    if touch_retest and (not touch or touch_check and touch_check["estado"] != "ok"):
        touch = touch_retest
    evidence = {
        "fecha": report["fecha"],
        "apk": apk_info,
        "resultado_verificacion": report["resultado"],
        "fallos_obligatorios": failures,
        "causas": diagnostics,
        "pantalla": {"resolucion_capturas": display,
                     # El lienzo lo mide cada captura, no una constante: la batería corre
                     # también sobre paneles de 2424x1080 y el literal 2400x1080 de antes
                     # marcaba "no" una pantalla correcta. Aquí se declaran los lienzos
                     # que hay de verdad entre las capturas archivadas.
                     "lienzos_medidos": sorted({f"{v['width']}x{v['height']}" for v in display.values()}),
                     "una_sola_resolucion": len({(v["width"], v["height"]) for v in display.values()}) == 1 if display else None,
                     "bandas_negras": False if all(c["estado"] == "ok" for c in checks if c["id"] in ("lienzo", "lienzo_final")) else None},
        "controles_dispositivo": touch,
        "retest_sha_instalado": retest,
        "retest_independiente_mismo_build": {
            "estado": "PASS" if touch_retest.get("estado") == "PASS" else "no confirmado",
            "sha_apk_instalado": apk_info.get("sha256"),
            "evidencia": retest.get("retest_mismo_sha_instalado", {}) if retest else {},
        },
        "limitaciones": ["No probado en un teléfono físico; la GPU/emulación del host no determina FPS o latencia en un móvil.",
                         "La corrida agregada verify.sh conserva fallos instrumentales; consultar fallos y el retest independiente."],
        "archivos": {"checks": str(out / "checks.tsv"), "touch_video": str(out / "shots/toque-hash-final/touch.mp4"),
                     "touch_json": str(out / "shots/toque-hash-final/touch.json")},
    }
    (Path(".tools/recovery") / "handoff-evidence.json").write_text(json.dumps(evidence, indent=2, ensure_ascii=False))

    print("%-22s %-9s %-9s %s" % ("comprobación", "estado", "segundos", "obligatoria"))
    for check in checks:
        print("%-22s %-9s %-9s %s" % (check["id"], check["estado"], check["segundos"], "sí" if check["obligatoria"] else "no"))
    print("\nresultado:", report["resultado"])
    print("fallos obligatorios:", failures or "ninguno")
    print("omitidas:", omitted or "ninguna")
    print("informe:", out / "verificacion-integral.json")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
