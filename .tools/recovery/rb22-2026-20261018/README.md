# RB22 2026 — auditoría e integración

Fecha: 18 de octubre de 2026.

## Qué contiene AC2026/rb

No es solo un skin. La carpeta contiene un coche completo en `f1_2026_rb22.kn5` (KN5 versión 6, sin cifrado, 106 MB), más `f1_2026_rb22_lod_b/c/d.kn5`, `collider.kn5`, datos `data/*.ini`, `driver_base_pos.knh`, texturas, extensión CSP y dos skins: Verstappen y Hadjar. La lectura estructural con `acgltf.kn5.load(..., geometry=False)` confirmó 633 nodos, 272 meshes, 222.201 vértices y 281.075 triángulos en el LOD A. El converter resolvió la decoración Verstappen y sustituyó dos mapas del modelo.

## Conversión e integración

- Conversión con la herramienta ya instalada `.tools/ac-gltf-venv/bin/kn5-to-gltf`, formato GLB autocontenido con skin `Verstappen`: 599 nodos, 249 meshes, 253.776 triángulos y 29 mapas embebidos; 29 MB.
- Activo del juego: [RB22-2026-Verstappen.glb](../../../assets/RB22-2026-Verstappen.glb).
- Agregado al selector como “Red Bull RB22 · 2026”; mantiene controlador y física compartidos del juego. Se canonicalizaron los pivotes `wheel_fl`, `wheel_fr`, `wheel_bl` y `wheel_br` a los cuatro nombres requeridos por el controlador, preservando sus transformaciones globales.
- La decoración instalada es la de Verstappen (piloto 3); no se convirtieron la skin Hadjar ni los LOD secundarios.

## Verificación Godot 4.7.2

Comprobaciones repetidas al cerrar la integración:

- `--headless --editor --path . --quit`: salida 0; inicialización del editor y escaneo/importación de recursos completados.
- `--headless --path . --script scripts/selection_probe.gd`: salida 0; PASS en las seis combinaciones (Barcelona y Suzuka × Red Bull del juego, McLaren MP4/4 y RB22 2026). El probe comprueba recursos de líneas y escenas, construcción de pista/coche, cuatro ruedas con nombres canónicos, inventario de colisiones (20 en Barcelona, 125 en Suzuka) y opciones del menú.
- `--headless --path . --quit-after 5`: salida 0; smoke test del menú sin errores.
- Evidencia: [probe final de selección](selection-probe-final.log), [import final del editor](editor-import-final.log), [smoke test final del menú](menu-smoke-final.log). Las pasadas previas están en [probe anterior](selection-probe.log), [importación del activo](import-installed-asset.log) y [smoke test anterior](main-menu-smoke.log).

La prueba cubre construcción y encaje en memoria; no es un test de conducción dinámica ni una inspección visual interactiva.

### Límites

La física del RB22 todavía usa la aproximación común del juego; no se integraron datos `data/*.ini` de aero, potencia, neumáticos o suspensión, ni se creó un rig de piloto/skinning dinámico. La verificación headless asegura el montaje y los recursos, pero no sustituye una inspección visual jugable del coche, la cámara ni la decoración en dispositivo.

## Fin de auditoría

El modelo importado y las seis combinaciones de pista/coche pasan las comprobaciones automatizadas de montaje en Godot. La calidad visual en movimiento y el comportamiento físico específico del RB22 quedan expresamente fuera de lo que estas sondas demuestran.

