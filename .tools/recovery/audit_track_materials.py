#!/usr/bin/env python3
"""Comprueba en el GLB entregado que los materiales PBR son los datos originales.

No se fía del informe de Blender: vuelve a leer el GLB, decodifica los mapas de
rugosidad empaquetados y los compara canal a canal con los PNG generados desde
los `*_MAP.dds` originales. También confirma que la malla sigue siendo la
variante de motos (nodos `*_moto`) y que no hay geometría de chicane.

Uso:  python3 .tools/recovery/audit_track_materials.py [ruta.glb]
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
META = ROOT / ".tools/recovery/source_metadata.json"
MANIFEST = ROOT / ".tools/recovery/pbr/roughness_manifest.json"
REPORT = ROOT / ".tools/recovery/pbr/track_material_audit.json"
MOTO_NODES = ("barcelona_remastered_moto", "barcelona_remastered_physics_moto")


def load_glb(path: Path):
    blob = path.read_bytes()
    import struct
    magic, version, length = struct.unpack_from("<III", blob)
    assert magic == 0x46546C67 and version == 2 and length == len(blob), "no es un GLB 2.0"
    size = struct.unpack_from("<I", blob, 12)[0]
    doc = json.loads(blob[20:20 + size])
    bin_size = struct.unpack_from("<I", blob, 20 + size)[0]
    assert struct.unpack_from("<I", blob, 24 + size)[0] == 0x004E4942
    return doc, blob[28 + size:28 + size + bin_size]


def image_bytes(doc, blob, index):
    view = doc["bufferViews"][doc["images"][index]["bufferView"]]
    start = view.get("byteOffset", 0)
    return blob[start:start + view["byteLength"]]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("glb", nargs="?", default=str(ROOT / "assets/BarcelonaMoto-Tutorial.glb"))
    args = ap.parse_args()
    path = Path(args.glb)

    doc, blob = load_glb(path)
    manifest = json.loads(MANIFEST.read_text())
    # El material declara el PNG generado; el manifest lo indexa por el DDS original.
    expected = {Path(st["png"]).name: st for st in manifest["mapas"].values()}
    meta = json.loads(META.read_text())

    # materiales del origen que declaran txMaps
    source_with_maps = [(kn5, m["name"], (m.get("textures") or {}).get("txMaps", ""))
                        for kn5, d in meta.items() for m in d["materials"]
                        if (m.get("textures") or {}).get("txMaps")]
    # Qué mapa declara cada material en el KN5 de origen, por nombre de material.
    origen = {}
    for kn5, nombre, txmaps in source_with_maps:
        origen.setdefault(nombre, []).append((kn5, txmaps))

    materials = doc["materials"]
    with_map, without_map, metallic_bad, map_missing = [], [], [], []
    roughness_values = []
    for mat in materials:
        extras = mat.get("extras") or {}
        declared = json.loads(extras.get("ac_material", "{}"))
        pbr = mat.get("pbrMetallicRoughness", {})
        name = mat.get("name", "")
        if declared.get("pbr", {}).get("roughness_map"):
            with_map.append(name)
            if "metallicRoughnessTexture" not in pbr:
                map_missing.append(name)
            if abs(float(pbr.get("metallicFactor", 1.0)) - 1.0) > 1e-6:
                metallic_bad.append((name, pbr.get("metallicFactor")))
            if abs(float(pbr.get("roughnessFactor", 1.0)) - 1.0) > 1e-6:
                metallic_bad.append((name, "roughnessFactor=" + str(pbr.get("roughnessFactor"))))
        else:
            without_map.append(name)
            roughness_values.append(round(float(pbr.get("roughnessFactor", 1.0)), 4))
            if "metallicRoughnessTexture" in pbr:
                map_missing.append(name + " (inesperado)")
            if abs(float(pbr.get("metallicFactor", 1.0))) > 1e-6:
                metallic_bad.append((name, "metallicFactor=" + str(pbr.get("metallicFactor"))))

    # Canales de los mapas realmente empaquetados, contra los PNG de origen.
    checked, channel_errors, sizes = 0, [], {}
    wanted = {}
    for mat in materials:
        extras = mat.get("extras") or {}
        declared = json.loads(extras.get("ac_material", "{}"))
        dds = declared.get("pbr", {}).get("roughness_map")
        if dds:
            wanted[mat["pbrMetallicRoughness"]["metallicRoughnessTexture"]["index"]] = dds
    for index, dds in sorted(wanted.items()):
        texture = doc["textures"][index]
        image_index = texture.get("source")
        data = image_bytes(doc, blob, image_index)
        embedded = Image.open(io.BytesIO(data))
        embedded.load()
        reference = Image.open(ROOT / expected[dds]["png"])
        reference.load()
        sizes[dds] = [embedded.width, embedded.height]
        if embedded.size != reference.size:
            channel_errors.append((dds, "tamano %s != %s" % (embedded.size, reference.size)))
            continue
        emb = embedded.convert("RGB").getchannel("G")
        ref = reference.getchannel("G")
        if emb.tobytes() != ref.tobytes():
            worst = max(abs(a - b) for a, b in zip(emb.tobytes(), ref.tobytes()))
            channel_errors.append((dds, "canal G distinto (peor delta %d)" % worst))
        blue = embedded.convert("RGB").getchannel("B").getextrema()
        if blue != (0, 0):
            channel_errors.append((dds, "canal B (metalicidad) no es cero: %s" % (blue,)))
        checked += 1

    # Correspondencia material a material. Sin esto la auditoría solo comprobaría
    # que los píxeles coinciden con el DDS que dice el GLB, no que ese DDS sea el
    # que el propio material declara en el origen: un mapa asignado por parecido
    # de nombres pasaría. Se exige que el nombre del material esté en el catálogo
    # original y que su txMaps sea exactamente el mapa empaquetado.
    correspondencia, fuera_del_origen = [], []
    for mat in materials:
        declared = json.loads((mat.get("extras") or {}).get("ac_material", "{}"))
        dds = declared.get("pbr", {}).get("roughness_map")
        if not dds:
            continue
        # Blender exporta el material como "<kn5 sin extensión>::<material>".
        nombre = mat.get("name", "").split("::")[-1]
        candidatos = origen.get(nombre)
        if not candidatos:
            fuera_del_origen.append({"material": nombre, "mapa": dds,
                                     "motivo": "el origen no declara txMaps para este material"})
            continue
        # El KN5 nombra el DDS y el GLB el PNG generado desde él: se compara el
        # nombre sin extensión.
        if Path(dds).stem not in [Path(t).stem for _, t in candidatos]:
            fuera_del_origen.append({"material": nombre, "mapa": dds,
                                     "motivo": "el origen declara %s" % sorted({t for _, t in candidatos})})
            continue
        correspondencia.append({"material": nombre, "mapa": dds,
                                "txMaps_del_origen": [t for _, t in candidatos
                                                      if Path(t).stem == Path(dds).stem][0],
                                "kn5": [k for k, t in candidatos
                                        if Path(t).stem == Path(dds).stem][0]})

    # Los lotes del GLB llevan en su propio nombre el KN5 del que salieron
    # (`barcelona_remastered_moto.obj__...`), que es donde se ve la variante.
    mesh_names = [n.get("name", "") for n in doc["nodes"] if "mesh" in n]
    moto = [n for n in mesh_names if "moto" in n.lower()]
    chicane = [n for n in mesh_names if "chicane" in n.lower()]

    report = {
        "glb": str(path.relative_to(ROOT)),
        "bytes": path.stat().st_size,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "materiales": len(materials),
        "imagenes": len(doc.get("images", [])),
        "materiales_con_mapa_rugosidad": len(with_map),
        "materiales_con_rugosidad_escalar": len(without_map),
        "mapas_en_el_origen_que_declaraban_txMaps": len(source_with_maps),
        "mapas_comprobados_canal_a_canal": checked,
        "errores_de_canal": channel_errors,
        "materiales_sin_metallicRoughnessTexture": map_missing,
        "materiales_con_metalicidad_no_neutra": metallic_bad,
        "correspondencia_material_a_mapa": correspondencia,
        "mapas_asignados_fuera_del_origen": fuera_del_origen,
        "valores_de_rugosidad_escalar": sorted(set(roughness_values)),
        "tamano_de_los_mapas_empaquetados": sizes,
        "nodos_de_la_capa_moto": moto,
        "nodos_de_chicane": chicane,
        "pasa": bool(with_map and not channel_errors and not map_missing
                     and not metallic_bad and not fuera_del_origen and moto and not chicane),
    }
    REPORT.write_text(json.dumps(report, indent=2, ensure_ascii=False))

    print("GLB:", report["glb"], "%.1f MB" % (report["bytes"] / 1048576.0))
    print("materiales: %d   con mapa de rugosidad: %d   con rugosidad escalar: %d"
          % (report["materiales"], report["materiales_con_mapa_rugosidad"],
             report["materiales_con_rugosidad_escalar"]))
    print("mapas empaquetados comprobados canal a canal: %d" % checked)
    print("valores escalares distintos: %d  %s"
          % (len(report["valores_de_rugosidad_escalar"]), report["valores_de_rugosidad_escalar"]))
    print("nodos de la capa moto: %d   nodos de chicane: %d" % (len(moto), len(chicane)))
    print("correspondencia material->mapa comprobada contra el KN5: %d" % len(correspondencia))
    for par in correspondencia:
        print("  %-28s %-24s %s" % (par["material"], par["mapa"], par["kn5"]))
    print("mapas asignados fuera del origen:", fuera_del_origen or "ninguno")
    print("errores de canal:", channel_errors or "ninguno")
    print("sin metallicRoughnessTexture:", map_missing or "ninguno")
    print("metalicidad no neutra:", metallic_bad or "ninguna")
    print("informe:", REPORT.relative_to(ROOT))
    print("AUDITORIA_PASA" if report["pasa"] else "AUDITORIA_FALLA")
    return 0 if report["pasa"] else 1


if __name__ == "__main__":
    sys.exit(main())
