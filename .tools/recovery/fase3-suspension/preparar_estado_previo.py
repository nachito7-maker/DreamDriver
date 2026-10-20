#!/usr/bin/env python3
"""Copia de recuperación de la fase 3.

Deja en `.tools/recovery/fase3-suspension/estado-previo/`:

  * `F1OneShot-BarcelonaMoto.apk`      — el APK de la fase 2 (byte a byte).
  * `estado-fase3/`                    — copia de los archivos TAL COMO quedan tras
                                         la fase 3 (por si hay que volver a este
                                         estado en lugar de al anterior).
  * `SHA256SUMS`                       — huellas de todo lo guardado.
  * `VOLVER-ATRAS.md`                  — qué cambió y cómo deshacerlo, con el APK
                                         como reversión exacta del entregable.

Uso:  python3 .tools/recovery/fase3-suspension/preparar_estado_previo.py
"""
from __future__ import annotations

import hashlib
import os
import shutil
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(AQUI, "..", "..", ".."))
OUT = os.path.join(AQUI, "estado-previo")
APK = os.path.join(ROOT, "build", "android", "F1OneShot-BarcelonaMoto.apk")
APK_FASE2 = "01b2ec6a4496401e89a16bc06741bf0c2d56b86bd9604bfa84c7ab84200b599f"

ARCHIVOS_FASE3 = [
    "scripts/wheel_suspension.gd",
    "scripts/suspension_probe.gd",
    "scripts/car_controller.gd",
    "scripts/car_wheel_probe.gd",
]

NUEVOS = ["scripts/wheel_suspension.gd", "scripts/suspension_probe.gd"]
MODIFICADOS = ["scripts/car_controller.gd", "scripts/car_wheel_probe.gd"]


def sha256(path: str) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    os.makedirs(os.path.join(OUT, "estado-fase3", "scripts"), exist_ok=True)
    problemas: list[str] = []

    if os.path.exists(APK):
        destino = os.path.join(OUT, "F1OneShot-BarcelonaMoto.apk")
        shutil.copy2(APK, destino)
        huella = sha256(destino)
        if huella != APK_FASE2:
            problemas.append("el APK copiado no es el de la fase 2: %s" % huella)
        print("[estado-previo] APK de la fase 2 copiado: %s" % huella)
    else:
        problemas.append("no existe el APK %s" % APK)

    for archivo in ARCHIVOS_FASE3:
        origen = os.path.join(ROOT, archivo)
        if not os.path.exists(origen):
            problemas.append("no existe %s" % archivo)
            continue
        shutil.copy2(origen, os.path.join(OUT, "estado-fase3", "scripts", os.path.basename(archivo)))

    with open(os.path.join(OUT, "SHA256SUMS"), "w", encoding="utf-8") as handle:
        handle.write("%s  F1OneShot-BarcelonaMoto.apk\n" % sha256(os.path.join(OUT, "F1OneShot-BarcelonaMoto.apk")))
        for archivo in ARCHIVOS_FASE3:
            ruta = os.path.join(OUT, "estado-fase3", archivo)
            if os.path.exists(ruta):
                handle.write("%s  estado-fase3/%s\n" % (sha256(ruta), archivo))

    with open(os.path.join(OUT, "VOLVER-ATRAS.md"), "w", encoding="utf-8") as handle:
        handle.write(
            "# Volver al estado previo a la fase 3\n\n"
            "## Reversión exacta del entregable\n\n"
            "El APK de la fase 2 está guardado aquí sin tocar:\n\n"
            "```sh\n"
            "cp .tools/recovery/fase3-suspension/estado-previo/F1OneShot-BarcelonaMoto.apk build/android/\n"
            "adb -s emulator-5556 install -r build/android/F1OneShot-BarcelonaMoto.apk\n"
            "```\n\n"
            "SHA-256: `%s`\n\n"
            "## Reversión del código\n\n"
            "La fase 3 AÑADE dos archivos y MODIFICA dos:\n\n"
            "* nuevos: %s\n"
            "* modificados: %s\n\n"
            "Para volver al código de la fase 2:\n\n"
            "```sh\n"
            "rm -f scripts/wheel_suspension.gd scripts/suspension_probe.gd\n"
            "```\n\n"
            "y deshacer los cambios del controlador, que están todos en funciones\n"
            "concretas y documentados en `.tools/recovery/fase3-suspension/INFORME-FASE3-SUSPENSION.md`\n"
            "(sección «Archivos modificados»): la suspensión por rueda entra en\n"
            "`_configure_suspension`, `_sample_wheel_contacts` y `_update_visuals`, y el\n"
            "balanceo y cabeceo prefijados de la fase 2 salían de\n"
            "`_update_engine_and_forces` (`_body_roll`, `_body_pitch`).\n\n"
            "## Estado de la fase 3\n\n"
            "En `estado-fase3/` queda copia de los cuatro archivos tal y como están al\n"
            "cerrar la fase, con sus huellas en `SHA256SUMS`.\n" % (APK_FASE2, ", ".join(NUEVOS), ", ".join(MODIFICADOS))
        )

    if problemas:
        print("\nPROBLEMAS:")
        for problema in problemas:
            print("  - %s" % problema)
        return 1
    print("estado previo listo en %s" % OUT)
    return 0


if __name__ == "__main__":
    sys.exit(main())
