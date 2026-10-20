import json
import struct
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
GLB = ROOT / "VehiclePrototypes/RedBull/source/RedBull.glb"


def read_glb(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67 and version == 2 and length == len(data)
    offset = 12
    gltf = None
    binary = b""
    while offset < length:
        chunk_len, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset:offset + chunk_len]
        offset += chunk_len
        if chunk_type == 0x4E4F534A:
            gltf = json.loads(chunk)
        elif chunk_type == 0x004E4942:
            binary = chunk
    return gltf, binary


def read_accessor(gltf, binary, index):
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    typ = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[acc["type"]]
    formats = {5126: "f", 5121: "B", 5123: "H", 5125: "I"}
    code = formats[acc["componentType"]]
    fmt = "<" + code * typ
    packed_size = struct.calcsize(fmt)
    stride = view.get("byteStride", packed_size)
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    values = []
    for i in range(acc["count"]):
        values.append(struct.unpack_from(fmt, binary, start + i * stride))
    return values


gltf, binary = read_glb(GLB)
print("GLB", GLB.relative_to(ROOT), "meshes", len(gltf["meshes"]), "materials", len(gltf["materials"]))
for mesh_index, mesh in enumerate(gltf["meshes"]):
    for primitive_index, primitive in enumerate(mesh["primitives"]):
        uv = primitive["attributes"].get("TEXCOORD_0")
        material_index = primitive.get("material")
        print("PRIMITIVE", mesh_index, mesh.get("name"), primitive_index,
              "vertices", gltf["accessors"][primitive["attributes"]["POSITION"]]["count"],
              "material", material_index,
              gltf["materials"][material_index].get("name") if material_index is not None else None,
              "uv_accessor", uv)
        if uv is None:
            continue
        coords = read_accessor(gltf, binary, uv)
        print(" UV_RANGE", [min(p[a] for p in coords) for a in range(2)],
              [max(p[a] for p in coords) for a in range(2)])
        img = Image.new("RGB", (2048, 2048), "white")
        draw = ImageDraw.Draw(img)
        indices = read_accessor(gltf, binary, primitive["indices"])
        flat = [v[0] for v in indices]
        for face in range(0, len(flat) - 2, 3):
            pts = []
            for idx in flat[face:face + 3]:
                u, v = coords[idx]
                pts.append((round(u * 2047), round((1.0 - v) * 2047)))
            draw.polygon(pts, fill=(221, 44, 28), outline=(18, 18, 18))
        out = ROOT / ".tools/recovery/redbull-skin-20261018" / f"source_uv_{mesh_index}_{primitive_index}_{mesh.get('name','mesh')}.png"
        img.save(out)
        print(" UV_PLOT", out.relative_to(ROOT))

for i, material in enumerate(gltf.get("materials", [])):
    pbr = material.get("pbrMetallicRoughness", {})
    def describe(ref):
        if not ref:
            return None
        ti = gltf["textures"][ref["index"]]
        source = ti.get("source")
        return {"texture": ref["index"], "image": source,
                "image_name": gltf["images"][source].get("name") if source is not None else None}
    print("MATERIAL", i, material.get("name"),
          "base", describe(pbr.get("baseColorTexture")),
          "mr", describe(pbr.get("metallicRoughnessTexture")),
          "normal", describe(material.get("normalTexture")),
          "emissive", describe(material.get("emissiveTexture")))