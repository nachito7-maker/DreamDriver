#!/usr/bin/env python3
"""Audita qué viaja de verdad dentro del APK.

En el anfitrión `res://` es el árbol de trabajo, así que cualquier script nuevo
se carga aunque el preset de exportación no lo declare. En el teléfono el APK
sólo lleva lo que el preset empaqueta: un `preload` que apunte a un archivo no
declarado hace fallar el script entero y el juego arranca sin él. Esta
comprobación lee el `include_filter` de `export_presets.cfg`, calcula el nombre
con el que Godot exporta cada archivo y exige encontrarlo en el ZIP; después
recorre los `res://` que precargan los scripts empaquetados y sus escenas.

Termina con código distinto de cero si falta algo.
"""

from __future__ import annotations

import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PRESET = ROOT / "export_presets.cfg"
APK = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "build/android/F1OneShot-BarcelonaMoto.apk"

# Godot guarda el contenido de res:// bajo assets/ dentro del APK.
PREFIX = "assets/"


def exported_names(path: str) -> list[str]:
    """APK names for a source resource and its Godot-imported destination."""
    if path.endswith(".gd"):
        return [path[:-3] + ".gdc", path]
    if path.endswith((".tscn", ".scn", ".tres")):
        return [path + ".remap", path]
    names = [path, path + ".import"]
    sidecar = ROOT / (path + ".import")
    if sidecar.is_file():
        data = sidecar.read_text(errors="replace")
        for destination in re.findall(r'"res://([^" ]+)"', data):
            if destination.startswith(".godot/imported/"):
                names.append(destination)
        for destination in re.findall(r'^path="res://([^"]+)"', data, re.M):
            if destination.startswith(".godot/imported/"):
                names.append(destination)
    return list(dict.fromkeys(names))


def dependencies(text: str) -> set[str]:
    """Rutas res:// citadas en un texto de script o de escena."""
    found = set()
    for raw in re.findall(r"res://[^\"'\n\s)]+", text):
        if raw.endswith((".gd", ".tscn", ".tres", ".scn", ".glb", ".fbx", ".png", ".json", ".ai")):
            found.add(raw[len("res://"):])
    for raw in re.findall(r'path="res://([^"]+)"', text):
        if raw.endswith((".gd", ".tscn", ".tres", ".scn")):
            found.add(raw)
    return found


def main() -> int:
    if not APK.exists():
        print(f"no existe el APK: {APK}")
        return 1
    if not PRESET.exists():
        print(f"no existe el preset: {PRESET}")
        return 1

    preset_text = PRESET.read_text()
    declared = re.search(r'^include_filter="([^"]*)"', preset_text, re.M)
    files = re.search(r'^export_files=PackedStringArray\((.*)\)$', preset_text, re.M)
    if declared is None or files is None:
        print("el preset no declara include_filter o export_files")
        return 1
    entries = [e.strip() for e in declared.group(1).split(",") if e.strip()]
    explicit = re.findall(r'"([^"]+)"', files.group(1))
    entries = list(dict.fromkeys(entries + [e.removeprefix("res://") for e in explicit]))

    with zipfile.ZipFile(APK) as apk:
        packaged = set(apk.namelist())
        missing: list[str] = []
        checked = 0
        for entry in entries:
            source = ROOT / entry
            if not source.exists():
                missing.append(f"{entry} (declarado en el preset y ausente del proyecto)")
                continue
            names = exported_names(entry)
            checked += 1
            if not any(PREFIX + name in packaged for name in names):
                missing.append(f"{entry} -> assets/{{{', '.join(names)}}}")

        print(f"preset: {len(entries)} archivos declarados (incluye export_files), {checked} nombres esperados en el APK")

        # Dependencias: todo res:// que precargue un script empaquetado o cite una
        # escena empaquetada tiene que viajar también.
        dangling: list[str] = []
        scanned = 0
        for entry in entries:
            source = ROOT / entry
            if not source.exists() or not entry.endswith((".gd", ".tscn")):
                continue
            scanned += 1
            for dep in sorted(dependencies(source.read_text(errors="replace"))):
                if dep == entry:
                    continue
                if not (ROOT / dep).exists():
                    dangling.append(f"{entry}: cita res://{dep}, que no está en el proyecto")
                    continue
                names = exported_names(dep)
                if not any(PREFIX + name in packaged for name in names):
                    dangling.append(f"{entry}: res://{dep} -> assets/{{{', '.join(names)}}}")
        print(f"dependencias: {scanned} fuentes revisadas")

        for label, problems in (("FALTA EN EL APK", missing), ("DEPENDENCIA ROTA", dangling)):
            for problem in problems:
                print(f"  {label}: {problem}")

        if missing or dangling:
            print(f"APK incompleto: {len(missing)} archivos del preset y {len(dangling)} dependencias fuera")
            return 1

    total = len([n for n in packaged if n.startswith(PREFIX) and not n.startswith(PREFIX + ".godot/")])
    print(f"empaquetado correcto: {total} archivos de res:// en el APK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
