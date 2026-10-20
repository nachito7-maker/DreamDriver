#!/usr/bin/env python3
"""Convierte los mapas de material originales de AC en mapas de rugosidad glTF.

QUÉ ES UN `*_MAP.dds` EN ASSETTO CORSA
--------------------------------------
La textura del slot `txMaps` de los shaders `ksPerPixelMultiMap` y
`ksPerPixelMultiMap_NMDetail` es, según la guía de texturizado del propio
pipeline de Assetto Corsa, el "material specular-gloss-ref map":

    R = intensidad especular      (no es metalicidad)
    G = glossiness / nitidez del reflejo
    B = intensidad de reflexión   (no es metalicidad)

Es decir, NO es un mapa ORM de glTF. Lo que sí se puede trasladar sin inventar
nada es el canal G: es literalmente el brillo de la superficie, y su
complemento es la rugosidad que glTF pide:

    roughness = 255 - G

Los otros dos canales se descartan a propósito: `R` y `B` son amplitudes de un
lobo Blinn-Phong, y el único hueco con el que glTF cuenta para eso es
KHR_materials_specular, que este proyecto no puede exigir. Meterlos como
metalicidad convertiría en cromo cada plástico pulido.

El resultado se escribe ya empaquetado como espera glTF para
`metallicRoughnessTexture`: R = oclusión (255, sin dato original que llevar),
G = rugosidad, B = metalicidad (0).

Los mapas se limitan a `--cap` píxeles de lado: la rugosidad varía a baja
frecuencia y el paquete se entrega en un teléfono.

Uso:  python3 .tools/recovery/bake_roughness_maps.py [--cap 512]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
META = ROOT / ".tools/recovery/source_metadata.json"
TEXTURES = ROOT / ".tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/texture"
OUTDIR = ROOT / ".tools/recovery/pbr/roughness"
MANIFEST = ROOT / ".tools/recovery/pbr/roughness_manifest.json"
SCALARS = ROOT / ".tools/recovery/pbr/material_roughness.json"


def scalar_roughness(props: dict) -> tuple[float, str]:
    """Exponente especular de AC -> rugosidad GGX (el ancho del brillo).

    La pista de AC es Blinn-Phong: `ksSpecularEXP` es el exponente, y
    `sqrt(2 / (exp + 2))` es la conversión estándar a la rugosidad de un lobo
    GGX equivalente, la misma aritmética que usa el conversor del proyecto en
    `.tools/assetto-corsa-gltf/src/acgltf/convert.py`.

    `ksSpecular` (la intensidad) se pliega en el exponente por la misma razón
    que allí: multiplica la cresta del lobo, que es lo que hace el exponente.
    Un material con intensidad 0 (56 de los 61 materiales de otra pista de este
    proyecto lo están) no tiene brillo especular en AC y debe salir mate.

    NO se pliega `tarmacSpecularMultiplier`. Esa cantidad pertenece al segundo
    lobo de `ksMultilayer_fresnel_nm`, modulado por fresnel y sin equivalente en
    glTF; doblarla en el exponente pondría el asfalto de la recta en 0,19 de
    rugosidad, que en un solo lobo GGX es un espejo. El circuito se entrega con
    el asfalto mate que ya estaba validado en el dispositivo.
    """
    exp = max(float(props.get("ksSpecularEXP", 20.0)), 1.0)
    spec = float(props.get("ksSpecular", 1.0))
    eff = exp * max(spec, 0.02)
    rough = min(max((2.0 / (eff + 2.0)) ** 0.5, 0.04), 1.0)
    return rough, "ksSpecularEXP=%.3f ksSpecular=%.3f" % (exp, spec)


def bake(dds: Path, cap: int) -> tuple[Image.Image, dict]:
    image = Image.open(dds)
    image.load()
    original = image.size
    gloss = image.convert("L") if image.mode == "L" else image.getchannel("G")
    if max(gloss.size) > cap:
        scale = cap / float(max(gloss.size))
        gloss = gloss.resize((max(int(gloss.size[0] * scale), 1),
                              max(int(gloss.size[1] * scale), 1)),
                             Image.LANCZOS)
    # G = glossiness: 255 es un espejo y 0 es completamente mate.
    rough = gloss.point(lambda v: 255 - v)
    stats = {
        "tamano_original": list(original),
        "tamano_escrito": list(rough.size),
        "glossiness_G": {"min": gloss.getextrema()[0], "max": gloss.getextrema()[1],
                         "media": round(sum(gloss.getdata()) / (rough.size[0] * rough.size[1]), 2)},
        "rugosidad": {"min": rough.getextrema()[0], "max": rough.getextrema()[1],
                      "media": round(sum(rough.getdata()) / (rough.size[0] * rough.size[1]), 2)},
    }
    neutral = Image.new("L", rough.size, 255)   # R = oclusion (sin dato original)
    metallic = Image.new("L", rough.size, 0)    # B = metalicidad (AC no la define)
    return Image.merge("RGB", (neutral, rough, metallic)), stats


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cap", type=int, default=512)
    args = ap.parse_args()

    meta = json.loads(META.read_text())
    materials = []
    used: dict[str, dict] = {}
    for kn5, data in meta.items():
        for mat in data["materials"]:
            props = mat.get("props") or {}
            texs = mat.get("textures") or {}
            rough, why = scalar_roughness(props)
            maps = texs.get("txMaps", "")
            entry = {
                "kn5": kn5,
                "name": mat["name"],
                "shader": mat.get("shader", ""),
                "rugosidad_escalar": round(rough, 6),
                "procedencia_escalar": why,
                "txMaps": maps,
                "mapa_rugosidad": None,
            }
            if maps:
                source = TEXTURES / maps
                if not source.is_file():
                    entry["error"] = "mapa ausente en el origen: %s" % maps
                else:
                    if maps not in used:
                        image, stats = bake(source, args.cap)
                        OUTDIR.mkdir(parents=True, exist_ok=True)
                        png = OUTDIR / (source.stem + ".png")
                        image.save(png, "PNG", optimize=True)
                        stats["origen"] = str(source)
                        stats["png"] = str(png.relative_to(ROOT))
                        stats["png_bytes"] = png.stat().st_size
                        stats["png_sha256"] = hashlib.sha256(png.read_bytes()).hexdigest()
                        used[maps] = stats
                    entry["mapa_rugosidad"] = used[maps]["png"]
            materials.append(entry)

    manifest = {
        "cap_px": args.cap,
        "materiales": len(materials),
        "materiales_con_mapa": sum(1 for m in materials if m["mapa_rugosidad"]),
        "mapas_distintos": len(used),
        "mapas": used,
    }
    SCALARS.write_text(json.dumps({"materiales": materials}, indent=2, ensure_ascii=False))
    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False))

    print("materiales: %d   con mapa de rugosidad: %d   mapas distintos: %d"
          % (manifest["materiales"], manifest["materiales_con_mapa"], manifest["mapas_distintos"]))
    print("bytes totales de los mapas: %d" % sum(m["png_bytes"] for m in used.values()))
    print()
    print("%-24s %-11s %-8s %-8s %-8s %s" % ("mapa", "escrito", "G media", "roughmin", "roughmed", "png KB"))
    for name, st in sorted(used.items()):
        print("%-24s %-11s %-8.1f %-8d %-8.1f %.1f"
              % (name[:24], "x".join(str(x) for x in st["tamano_escrito"]),
                 st["glossiness_G"]["media"], st["rugosidad"]["min"],
                 st["rugosidad"]["media"], st["png_bytes"] / 1024.0))
    print()
    print("archivos escritos:")
    print("  ", SCALARS.relative_to(ROOT))
    print("  ", MANIFEST.relative_to(ROOT))
    print("  ", OUTDIR.relative_to(ROOT), "/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
