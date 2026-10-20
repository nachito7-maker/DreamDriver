import json, struct, hashlib, io, configparser
from pathlib import Path
from PIL import Image

def load(path):
    b = Path(path).read_bytes()
    magic, ver, length = struct.unpack_from('<III', b)
    assert magic == 0x46546c67 and ver == 2 and length == len(b)
    n = struct.unpack_from('<I', b, 12)[0]
    g = json.loads(b[20:20+n])
    bn, bt = struct.unpack_from('<II', b, 20+n)
    assert bt == 0x004e4942
    return g, b[28+n:28+n+bn]

ini = configparser.ConfigParser()
ini.read('.tools/tutorial-conversion/input/models_barcelona_2023.ini')
models = [ini[s]['FILE'] for s in ini.sections() if s.startswith('MODEL_')]
assert 'barcelona_remastered_moto.kn5' in models
assert 'barcelona_remastered_physics_moto.kn5' in models
assert not any('chicane' in m.lower() for m in models)
g, blob = load('assets/BarcelonaMoto-Tutorial.glb')
# Las 123 texturas originales del mod siguen siendo exactamente las mismas: se
# cuentan por el uso que les dan los materiales, no por el total, que ahora
# incluye ademas los 22 mapas de rugosidad derivados de los *_MAP.dds.
color = set()
normals = set()
roughness = set()
for m in g['materials']:
    pbr = m['pbrMetallicRoughness']
    if 'baseColorTexture' in pbr:
        color.add(g['textures'][pbr['baseColorTexture']['index']]['source'])
    if 'normalTexture' in m:
        normals.add(g['textures'][m['normalTexture']['index']]['source'])
    if 'metallicRoughnessTexture' in pbr:
        roughness.add(g['textures'][pbr['metallicRoughnessTexture']['index']]['source'])
# 99 albedos distintos + 24 normales distintas = las 123 texturas del mod.
assert len(color) == 99, len(color)
assert len(normals) == 24, len(normals)
assert len(color | normals) == 123, len(color | normals)
assert not (color & normals), 'un albedo no puede ser tambien normal'
assert len(roughness) == 22, len(roughness)
assert not (roughness & (color | normals)), 'un mapa de rugosidad reutiliza una textura original'
assert len(g['images']) == 123 + 22, len(g['images'])
for im in g['images']:
    v = g['bufferViews'][im['bufferView']]
    image = Image.open(io.BytesIO(blob[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]))
    image.load()
    assert image.width and image.height
nodes = g['nodes']
source_meta = json.loads(Path('.tools/recovery/source_metadata.json').read_text())
for model in source_meta.values():
    model['nodes'] = {name.replace(' ', '_'): data for name,data in model['nodes'].items()}
counts = {}
source_names = {}
for node in nodes:
    if 'mesh' not in node: continue
    ex = node['extras']
    src = ex['kn5_source_obj']
    counts[src] = counts.get(src,0) + sum(g['accessors'][p['indices']]['count']//3 for p in g['meshes'][node['mesh']]['primitives'])
    names = json.loads(ex['ac_source_nodes'])
    source_names.setdefault(src,[]).extend(names)
removed = json.loads(Path('.tools/recovery/obj_validation_removed_faces.json').read_text())
assert sum(x['removed'] for x in removed) == 20
for src, count in counts.items():
    expected = sum(source_meta[src]['nodes'][name]['triangles'] for name in source_names[src])
    # Independently re-imported ordinary OBJ: Blender validates duplicate/invalid
    # faces. No decimation or geometric approximation is used for the circuit.
    validated_removed = sum(x['removed'] for x in removed) if src == 'barcelona_remastered.obj' else 0
    assert count == expected - validated_removed, (src,count,expected,validated_removed)
for name in ['12TRM-BRC033','12TRM-BRC034','12TRM-BRC035']:
    assert name in source_names['barcelona_remastered_physics_moto.obj']
assert len([n for n in nodes if n.get('extras',{}).get('ac_physics')]) == 22
car, cb = load('assets/RedBull-Drive.glb')
assert {n['name'] for n in car['nodes']} == {'Body','wheel_fl','wheel_fr','wheel_rl','wheel_rr'}


def matrix_of(node):
    if 'matrix' in node:
        return node['matrix']
    t = node.get('translation', [0.0, 0.0, 0.0])
    x, y, z, w = node.get('rotation', [0.0, 0.0, 0.0, 1.0])
    sx, sy, sz = node.get('scale', [1.0, 1.0, 1.0])
    return [(1 - 2 * (y * y + z * z)) * sx, 2 * (x * y + z * w) * sx, 2 * (x * z - y * w) * sx, 0,
            2 * (x * y - z * w) * sy, (1 - 2 * (x * x + z * z)) * sy, 2 * (y * z + x * w) * sy, 0,
            2 * (x * z + y * w) * sz, 2 * (y * z - x * w) * sz, (1 - 2 * (x * x + y * y)) * sz, 0,
            t[0], t[1], t[2], 1]


def to_world(m, point):
    return [sum(m[c * 4 + r] * point[c] for c in range(3)) + m[12 + r] for r in range(3)]


# --- ruedas del coche entregado -------------------------------------------
# El pivote de cada rueda tiene que estar EN EL CENTRO de su malla (si no, la
# rueda orbita en vez de girar), el eje de giro tiene que ser el lateral, las
# cuatro ruedas tienen que apoyar en el MISMO plano (y = 0 del modelo) y el
# suelo del chasis tiene que quedar por encima de ese plano. Es la comprobación
# del activo que acompaña a la sonda de ejecución `car_wheel_probe.gd`.
ruedas = {}
chasis_fondo = None
for node in car['nodes']:
    if 'mesh' not in node:
        continue
    m = matrix_of(node)
    lo = [1e9] * 3
    hi = [-1e9] * 3
    for prim in car['meshes'][node['mesh']]['primitives']:
        acc = car['accessors'][prim['attributes']['POSITION']]
        for c in range(3):
            lo[c] = min(lo[c], acc['min'][c])
            hi[c] = max(hi[c], acc['max'][c])
    corners = [[a, b, c] for a in (lo[0], hi[0]) for b in (lo[1], hi[1]) for c in (lo[2], hi[2])]
    world = [to_world(m, c) for c in corners]
    limites = {'x': (min(p[0] for p in world), max(p[0] for p in world)),
               'y': (min(p[1] for p in world), max(p[1] for p in world)),
               'z': (min(p[2] for p in world), max(p[2] for p in world))}
    if node['name'] == 'Body':
        chasis_fondo = limites['y'][0]
        continue
    rot = node.get('rotation', [0.0, 0.0, 0.0, 1.0])
    escala = node.get('scale', [1.0, 1.0, 1.0])
    # El nodo de la rueda no puede llevar rotación ni escala horneadas: el giro
    # lo aplica el juego sobre el nodo limpio.
    assert max(abs(r) for r in rot[:3]) < 1e-4 and abs(rot[3] - 1.0) < 1e-4, (node['name'], rot)
    assert all(abs(s - 1.0) < 1e-6 for s in escala), (node['name'], escala)
    tam = [hi[c] - lo[c] for c in range(3)]
    # El eje de giro es el de menor extensión de la caja y tiene que ser el
    # lateral (x), no el longitudinal ni el vertical.
    assert tam[0] < tam[1] and tam[0] < tam[2], (node['name'], tam)
    pivote = [lo[c] + tam[c] * 0.5 for c in range(3)]
    assert max(abs(p) for p in pivote) < 0.001, (node['name'], pivote)
    radio = tam[1] * 0.5
    assert 0.30 <= radio <= 0.45, (node['name'], radio)
    assert 0.25 <= tam[0] <= 0.55, (node['name'], tam[0])
    ruedas[node['name']] = {'fondo_m': limites['y'][0], 'techo_m': limites['y'][1],
                            'radio_m': radio, 'anchura_m': tam[0], 'pivote_m': pivote}
assert len(ruedas) == 4, ruedas
for nombre, r in ruedas.items():
    # Cada rueda apoya en el plano de contacto del modelo (y = 0).
    assert abs(r['fondo_m']) < 0.001, (nombre, r['fondo_m'])
assert max(r['fondo_m'] for r in ruedas.values()) - min(r['fondo_m'] for r in ruedas.values()) < 0.001
# El chasis no puede ir por debajo de las ruedas.
assert chasis_fondo > 0.0, chasis_fondo
raw = Path('assets/BarcelonaMoto.fast_lane.ai').read_bytes()
count = struct.unpack_from('<i', raw,4)[0]
assert count == 3057
source = Path('.tools/ac-source/Barcelona 3.1/fn_barcelona/barcelona_2023/ai/fast_lane.ai').read_bytes()
assert source == raw
report = {'passed':True,'models':models,'embedded_images_decoded':len(g['images']),'materials':len(g['materials']),
          'geometry_batches':len(g['meshes']),'triangle_counts_after_obj_validation':counts, 'obj_import_validation_removed':removed,
          'car_parts': [n['name']for n in car['nodes']], 'ai_points':count,
          'car_wheels': ruedas, 'car_floor_m': chasis_fondo,
          'sha256':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in [Path('assets/BarcelonaMoto-Tutorial.glb'),Path('assets/RedBull-Drive.glb'),Path('build/android/F1OneShot-BarcelonaMoto.apk')]}}
Path('.tools/recovery/artifact_audit.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
