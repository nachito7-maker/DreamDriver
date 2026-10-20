from pathlib import Path
import json, types

# Metadata-only extension of the locally installed open-source KN5 reader.
# Geometry still comes exclusively from jes/kn5-converter's OBJ output.
src = Path('.tools/assetto-corsa-gltf/src/acgltf/kn5.py').read_text()
src = src.replace("'nverts', 'ntris')", "'nverts', 'ntris', 'visible', 'renderable')")
src = src.replace('self.active = True', 'self.active = True\n        self.visible = self.renderable = True')
src = src.replace('r.u8(); r.u8(); r.u8()        # castShadows, visible, transparent', 'r.u8(); n.visible = bool(r.u8()); r.u8()')
src = src.replace('r.u8()                    # isRenderable', 'n.renderable = bool(r.u8())')
reader = types.ModuleType('metadata_reader')
exec(compile(src, 'metadata_reader', 'exec'), reader.__dict__)
report = {}
for path in sorted(Path('.tools/tutorial-conversion/input').glob('*.kn5')):
    model = reader.load(path, geometry=False)
    assert not model.encrypted, path
    nodes = {n.name: {'active': n.active, 'visible': n.visible, 'renderable': n.renderable,
                      'material': n.material, 'triangles': n.ntris}
             for n, _ in model.walk() if n.type in (2, 3)}
    report[path.with_suffix('.obj').name] = {'nodes': nodes, 'materials': model.materials}
    print(path.name, 'meshes', len(nodes), 'renderable', sum(n['renderable'] and n['visible'] for n in nodes.values()))
Path('.tools/recovery/source_metadata.json').write_text(json.dumps(report, indent=2))
