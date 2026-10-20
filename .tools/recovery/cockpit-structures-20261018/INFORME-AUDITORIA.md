# Auditoría de estructuras negras en cámara de morro

**Proyecto:** F1 One Shot · Godot 4.7.2 · **Fecha:** 2026-10-18

## Estado

Se corrigió primero una fuente común de obstrucción, demostrada por aislamiento: el juego estaba creando en cámara tres cajas negras que imitaban un halo —dos soportes laterales y un pilar central—, no eran piezas de los GLB. Se retiró esa geometría sintética de la vista de morro y se conservó el volante compacto y el display. La prueba de aislamiento encontró además un miembro de suspensión importado del MP4/4 que obstruía esa vista; se ocultó sólo en la cámara de morro y sigue visible en exterior. No se modificaron los originales ni conversiones de Assetto Corsa, física, dirección, motor, transmisión, circuito, controles o HUD.

## Piezas exactas y atribución

### 1. Estructura lateral izquierda (la grande inclinada)
- **Nodo antiguo:** `Race/Nose camera/Onboard cockpit details/Halo side support` (hijo izquierdo).
- **Código que la generaba:** `scripts/race.gd`, dentro de `_build_onboard_cockpit()`.
- **Tipo y dimensiones:** `BoxMesh`, `(0.055, 0.38, 0.06)` m; posición cámara-local `(-0.40, -0.41, -1.18)` m; rotación Z `+26°`; escala `(1,1,1)`; layer 2.
- **Origen:** geometría sintética de Godot, no importada del coche. Las capturas aisladas muestran que la caja rectangular se extiende sobre el neumático/carrocería y no se apoya en la geometría del halo real.

### 2. Estructura lateral derecha
- **Nodo antiguo:** segundo `Halo side support` (sin nombre estable asignado; el runtime lo generaba como `@MeshInstance3D@...`).
- **Dimensiones y origen:** el mismo `BoxMesh (0.055, 0.38, 0.06)` m, simétrico en `(+0.40, -0.41, -1.18)`, Z `-26°`, layer 2. Era también una pieza sintética distinta, no una malla fuente.

### 3. Barra vertical central
- **Nodo antiguo:** `Race/Nose camera/Onboard cockpit details/Halo center pillar`.
- **Tipo y dimensiones:** `BoxMesh`, `(0.032, 0.24, 0.045)` m; posición local `(0, -0.30, -1.15)` m; rotación cero; escala `(1,1,1)`; layer 2.
- **Origen:** geometría sintética de Godot; no es un objeto de los GLB.

Las tres eran mallas hermanas independientes bajo detalles de cámara; ninguna era auxiliar de Assetto Corsa ni formaba parte de colisión/física. Los respaldos con jerarquía, cajas, materiales y transformaciones están en `isolation-run.log` y las capturas diferenciales de `isolation/`.

## Comparación de los vehículos y causa común

No hay plantilla de conversión compartida en las piezas: los GLB y sus árboles son distintos. La causa compartida era el constructor de cabina en espacio de cámara de `scripts/race.gd`, que insertaba exactamente las mismas tres cajas en ambas selecciones.

- **RB22 2026:** `assets/RB22-2026-Verstappen.glb`, 249 objetos mesh en Blender. Incluye halo original importado bajo `RB22-2026/FBX_ redbull_fbx/hal/hal_SUB0/hal_SUB02`, `hal_SUB1/hal_SUB12` y `hal_SUB2/hal_SUB22`; los AABB de esas mallas están aproximadamente entre 4 y 28 cm y su jerarquía local está en escala 1. El modelo trae también cockpit, volante, espejos, suspensión y ruedas.
- **McLaren MP4/4:** `assets/MP44-Senna.glb`, 94 objetos mesh en Blender. Tiene cockpit bajo `senna_mp44_r02/FBX_ mclaren_mp44_a_fbx/BOD_LOD0/cockpit_4/cockpit_4_001` (AABB aproximado 0.554×1.118×0.513 m) y componentes propios de volante. Es un modelo histórico sin halo; no se deben inventar railes de halo sobre la carrocería. Sus brazos importados se conservaron; las capturas posteriores confirman que el único miembro que causa la obstrucción de morro es `wishbone_LF_2_001`.

La sonda de Godot confirma el contraste: al ocultar de uno en uno cada caja sintética se quita su silueta correspondiente; con esas cajas ocultas el RB22 aún conserva sus mallas `hal_SUB*` legítimas. Por ello no se ocultó el halo importado ni se modificaron de la misma manera los GLB. La corrección compartida entre coches es retirar los tres adornos sintéticos; el ajuste adicional del wishbone se limita al MP4/4 y no afecta al RB22.

## Capturas antes/después

- Aislamiento de las cajas sintéticas y del halo fuente: [primer plano RB22](isolation/rb22-isolation-crop.jpg), [primer plano McLaren](isolation/mclaren-isolation-crop.jpg), [capturas individuales](isolation/).

- Captura final post-cambio OpenGL de las cuatro combinaciones: [comparativa final](final/comparativa-final.jpg); archivos PNG nativos: [McLaren morro](final/mclaren-nose.png), [McLaren exterior](final/mclaren-exterior.png), [RB22 morro](final/rb22_2026-nose.png), [RB22 exterior](final/rb22_2026-exterior.png). La captura se volvió a ejecutar después de corregir la salida al directorio `final/`; el log anterior de captura fallida se conserva por trazabilidad.

> **Nota de comparación:** las vistas final y baseline no son una comparación pixel-a-pixel inmóvil porque el coche/escena avanzan mientras se captura. La atribución del cambio visual se basa en la prueba controlada de aislamiento, hecha a pose fija: [wishbone antes/después/exterior](diagnostics/mclaren/wishbone-cull-review.jpg). Esa prueba muestra el componente en el morro, su ausencia sólo en la cámara de morro y su conservación en exterior.

## Líneas rojas

En los archivos de producción no hay `ImmediateMesh`, `draw_line`, debug ray renderer ni configuración de debug de colisiones. `scripts/car_controller.gd` lanza raycasts de suspensión sin representación. La línea roja/verde visible es intencional: `Race/Assistance line`, creada por `scripts/race.gd::_build_assistance_line()` y dibujada mediante el ArrayMesh/material de `scripts/driving_line.gd`; su rojo significa aviso de frenada. No es un elemento del coche ni una sonda de suspensión, por lo que se conserva como ayuda de conducción.

## Cambio y recuperación

- Cambios de producción en [scripts/race.gd](../../../scripts/race.gd): se retiró la creación de los tres BoxMesh sintéticos laterales/central; volante y display no cambian. Además, sólo para McLaren, se asigna `wishbone_LF_2_001` a la capa 3, excluida del cull mask de morro e incluida en el de persecución. No se modifica su malla, material, transformación ni colisiones. En RB22 se conservan máscara, halo y geometría fuente.
- Copia previa del archivo: [respaldo recuperable](before/race.gd).
- No se escribieron cambios a los GLB originales. Auditoría Blender no destructiva: [script de auditoría](audit_glb.py), [inventario Blender](blender-mesh-audit.txt), [log de importación](blender-audit-run.log).

## Pruebas y limitaciones restantes

- `Godot --headless --path . --check-only --script .tools/recovery/cockpit-structures-20261018/capture_final_verified.gd`: pasó parseo después del arreglo de máscara; log [final-parse-current.log](final-parse-current.log).
- Captura OpenGL final: `FINAL_VERIFICATION failures=0`; cuatro imágenes 1280×576 guardadas en `final/`; log [final-capture-current.log](final-capture-current.log). La prueba de integridad confirma ruedas (4 por coche), 94 mallas visibles/110 superficies en McLaren, 249/249 en RB22 y tres meshes halo originales RB22.
- Aislamiento selectivo McLaren: una sola malla (`wishbone_LF_2_001`) cambia a layer 3; la cámara morro la excluye y la persecución la ve. La prueba visual y su resultado están en [wishbone-cull-review.jpg](diagnostics/mclaren/wishbone-cull-review.jpg) y [wishbone-probe.log](wishbone-probe.log).
- La prueba de aislamiento del estado pre-cambio guardó todas las vistas y geometrías en [isolation-run.log](isolation-run.log). La separación de cada caja quedó evidenciada visualmente.
- Blender auditó ambos GLB y guardó dimensiones/transformaciones de cada objeto mesh. No se reexportaron ni modificaron los originales.
- No se ejecutó la batería completa de dinámica, ruedas/suspensión, materiales o instalación en Android después de este cambio de geometría; la modificación no altera esos subsistemas, pero esos resultados no se declaran probados para esta versión.
- No se regeneró APK en este hilo.
