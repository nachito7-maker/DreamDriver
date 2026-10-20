#!/usr/bin/env python3
"""Audita los materiales originales de Assetto Corsa antes de tocarlos.

La pista de AC es Blinn-Phong: cada material declara `ksSpecular` (intensidad del
brillo) y `ksSpecularEXP` (su exponente). El exponente SÍ se convierte a rugosidad
de forma honesta:

    eff   = ksSpecularEXP * max(ksSpecular, 0.02)      (multiplicador de la cresta)
    rough = clamp(sqrt(2 / (eff + 2)), 0.04, 1.0)      (Blinn -> GGX)

que es exactamente la conversión documentada en
`.tools/assetto-corsa-gltf/src/acgltf/convert.py` (add_materials / bake_roughness).
El color especular no tiene equivalente en glTF, así que `metallic` queda en 0:
inventar metal a partir de la intensidad especular convierte en cromo cualquier
plástico pulido.

El canal R de `txMaps` (*_MAP.dds) es el multiplicador de intensidad por píxel y se
aplica encima del exponente, como en AC. El canal G se mide aquí para comprobar si
aporta variación de brillo (en AC suele ser un 255 plano).

Uso:  python3 .tools/recovery/audit_materials.py [--json SALIDA]
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
META = ROOT / ".tools/recovery/source_metadata.json"
TEXTURES = ROOT / ".tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture"
OUT = ROOT / ".tools/recovery/material_audit.json"

# Nombres con los que AC etiqueta cada clase de superficie en esta pista.
CLASSES = (
    ("asfalto", ("road", "asph", "tarmac", "pits")),
    ("pianos", ("curb", "kerb", "rumble", "kerb")),
    ("barreras", ("wall", "barrier", "guard", "fence", "jersey")),
    ("escapatorias", ("gravel", "sand", "trav", "grass", "green", "carpet")),
)


def to_roughness(exp: float, spec: float) -> float:
    eff = max(exp, 1.0) * max(spec, 0.02)
    return min(max(math.sqrt(2.0 / (eff + 2.0)), 0.04), 1.0)


def classify(name: str) -> str:
    lowered = name.lower()
    for label, keys in CLASSES:
        if any(k in lowered for k in keys):
            return label
    return "otro"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", default=str(OUT))
    args = ap.parse_args()

    meta = json.loads(META.read_text())
    on_disk = {p.name.lower(): p for p in TEXTURES.glob("*.dds")}
    png_beside = {p.name.lower(): p for p in TEXTURES.glob("*.png")}

    materials = []
    for kn5, data in meta.items():
        for mat in data["materials"]:
            props = mat.get("props") or {}
            texs = mat.get("textures") or {}
            shader = mat.get("shader", "")
            exp = float(props.get("ksSpecularEXP", 20.0))
            spec = float(props.get("ksSpecular", 1.0))
            note = ""
            if "multilayer" in shader.lower() and float(props.get("fresnelMaxLevel", 0.0)) > 0.0:
                tarmac = float(props.get("tarmacSpecularMultiplier", spec))
                if tarmac > spec:
                    spec = tarmac
                    note = "tarmacSpecularMultiplier"
            maps = texs.get("txMaps", "")
            materials.append({
                "kn5": kn5,
                "name": mat["name"],
                "key": "%s::%s" % (Path(kn5).stem, mat["name"]),
                "shader": shader,
                "ksSpecular": spec,
                "ksSpecularEXP": exp,
                "effective_exponent": round(exp * max(spec, 0.02), 3),
                "roughness": round(to_roughness(exp, spec), 4),
                "note": note,
                "alpha_blend": bool(mat.get("alpha_blend")),
                "alpha_tested": bool(mat.get("alpha_tested")),
                "txMaps": maps,
                "txMaps_on_disk": bool(maps) and maps.lower() in on_disk,
                "txMaps_png_beside": bool(maps) and (maps.lower()[:-4] + ".png") in png_beside,
                "class": classify(mat["name"]),
            })

    total = len(materials)
    with_maps = [m for m in materials if m["txMaps"]]
    resolvable = [m for m in with_maps if m["txMaps_on_disk"] or m["txMaps_png_beside"]]
    rough_by_class: dict[str, list[float]] = {}
    for m in materials:
        rough_by_class.setdefault(m["class"], []).append(m["roughness"])

    print("materiales: %d   con txMaps: %d   txMaps resoluble: %d"
          % (total, len(with_maps), len(resolvable)))
    print("imagenes .dds en el origen: %d" % len(on_disk))
    print()
    print("%-9s %-5s %-8s %-8s %s" % ("clase", "n", "rough.min", "rough.max", "materiales de ejemplo"))
    for label in ("asfalto", "pianos", "barreras", "escapatorias", "otro"):
        vals = rough_by_class.get(label)
        if not vals:
            continue
        examples = [m["name"] for m in materials if m["class"] == label][:4]
        print("%-9s %-5d %-8.3f %-8.3f %s" % (label, len(vals), min(vals), max(vals), ", ".join(examples)))
    print()
    print("materiales de la pista con mapa de rugosidad (txMaps):")
    for m in sorted(with_maps, key=lambda m: m["name"]):
        print("  %-22s %-28s exp=%-7.1f rough=%.3f  %s%s"
              % (m["name"][:22], m["txMaps"][:28], m["ksSpecularEXP"], m["roughness"],
                 "dds" if m["txMaps_on_disk"] else ("png" if m["txMaps_png_beside"] else "AUSENTE"),
                 "  [" + m["note"] + "]" if m["note"] else ""))
    print()
    hist = Counter(round(m["roughness"], 2) for m in materials)
    print("histograma de rugosidad (antes: 0.85 uniforme):", sorted(hist.items()))

    report = {
        "materiales": total,
        "con_txMaps": len(with_maps),
        "txMaps_resoluble": len(resolvable),
        "dds_en_origen": len(on_disk),
        "rugosidad_por_clase": {k: {"n": len(v), "min": min(v), "max": max(v)}
                               for k, v in rough_by_class.items()},
        "histograma_rugosidad": {str(k): v for k, v in sorted(hist.items())},
        "materiales": materials,
    }
    Path(args.json).write_text(json.dumps(report, indent=2, ensure_ascii=False))
    print("\ninforme:", args.json)
    return 0


if __name__ == "__main__":
    sys.exit(main())
