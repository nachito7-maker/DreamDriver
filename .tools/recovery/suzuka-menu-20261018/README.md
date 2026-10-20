# Integración de Suzuka GP y menú de selección

Fecha: 18 de octubre de 2026.

## Entrega

- El menú de inicio permite escoger Barcelona-Catalunya Moto o Suzuka GP y Red Bull RB22 o McLaren MP4/4 de Senna. El arranque conserva las selecciones en `TrackScript`; desde el HUD se puede volver al menú.
- Suzuka se importa desde el glTF convertido, sin intentar cargar el KN5 o iniciar Assetto Corsa durante la partida. La fast line e ideal line conservan el formato binario AI de AC, coordenadas `(-X, Y, -Z)`, y superficies en JSON.
- Los coches conservan un controlador/física comunes y se monta uno de los GLB existentes, cada cual con sus cuatro pivotes de rueda. Este trabajo no convierte ni modifica parámetros de física AC.
- El archivo completo de `track_data.gd` previo a reparar el estado local dañado se conserva como `track_data.preexisting-damage-backup.gd` en este directorio. Este respaldo sólo sirve para referencia/recuperación; no es un recurso del juego.

## Verificación ejecutada

Con Godot 4.7.2:

1. `--headless --editor --path . --quit`: importa el GLTF de Suzuka (142 batches de datos pesados, malla final de 914 meshes) y no deja errores de parseo en los scripts.
2. `--headless --path . --script scripts/selection_probe.gd`: pasó las cuatro combinaciones; comprobó fast/ideal line, construcción de coches y cuatro ruedas, y la presencia de colisiones de calzada, muros y escapatoria. Recuento por pista: Barcelona 20 colisionadores (3 calzada, 1 muro, 5 escapatoria) y Suzuka 125 (42 calzada, 18 muros, 21 escapatoria).
3. La sonda también instancia el menú y verifica las opciones de Suzuka y McLaren.
4. `--headless --path . --quit-after 5`: inicio de la escena principal por defecto (menú) sin errores.

La prueba también descubrió y corrigió una discrepancia de importación: en Barcelona el importador lee `ac_physics` desde los extras del StaticBody y `ac_source_nodes` es una lista JSON; Suzuka, en cambio, conserva nombres de nodos `1ROAD…` y metadatos de superficies laterales. La carga de físicas ahora resuelve ambas representaciones.

La geometría importa como colisión a nivel de escena y la sonda confirma los inventarios, pero no se afirma equivalencia física con AC: queda una pasada específica de ruta/contactos en Suzuka y pruebas manuales de cada salida/cambio de superficie. El smoke test headless del menú terminó sin errores. La sonda emitió una advertencia de una instancia ObjectDB filtrada al terminar, después de completar todas las comprobaciones PASS.

Registros de las pruebas: [selección y colisiones](selection-probe-final.log) y [arranque del menú](main-menu-smoke.log).

## Nota de medidas

El conteo de Suzuka en `data/ai/fast_lane.ai` es 3.585 y su poligonal mide 5.770,5 m; la tabla declara 5.770,5 m. El fast lane de Barcelona conserva 3.057 puntos/4.611,4 m muestreados y la ideal line tiene 2.984 puntos. El contrato de Barcelona marca 4.727 m de longitud de layout: la comprobación tolera una diferencia de 160 m para la aproximación poligonal; no se altera su trazada ni se falsean sus conteos para cuadrar ambas magnitudes.

## Archivos cambiados

`project.godot`, `scenes/main_menu.tscn`, `scripts/main_menu.gd`, `scripts/race.gd`, `scripts/race_hud.gd`, `scripts/track_data.gd` y `scripts/selection_probe.gd`. La conversión ya presente incluye `assets/suzuka-gp.gltf`, `assets/suzuka-gp.bin`, `assets/Suzuka.fast_lane.ai`, `assets/Suzuka.ideal_line.ai`, `assets/Suzuka.surfaces.json` y `assets/Suzuka-map.png`.

## RB22 2026 (seguimiento, 18 oct.)

La carpeta `AC2026/rb` incluye coche completo (KN5 V6 no cifrado: 633 nodos, 272 meshes y 281.075 triángulos), 3 LOD adicionales y dos skins de piloto. Se convirtió el LOD principal con la decoración Verstappen mediante `assetto-corsa-gltf`; resultado de 599 nodos / 249 meshes / 253.776 triángulos en [RB22-2026-Verstappen.glb](../../../../assets/RB22-2026-Verstappen.glb) (~29 MB). Se agregó al selector y se adaptaron los cuatro pivotes originales.

Verificado con Godot 4.7.2: importación GLB, arranque del menú y las seis combinaciones pista/coche; RB22 aparece con cuatro ruedas y las colisiones de pista esperadas. El registro está en [selection-probe.log](../rb22-2026-20261018/selection-probe.log) y [main-menu-smoke.log](../rb22-2026-20261018/main-menu-smoke.log). Limitación: el RB22 usa el controlador físico común aproximado del juego, no se importaron aero/powertrain/suspensiones de AC ni driver/skinning dinámico; las skins Hadjar y LOD B/C/D no se integran aún.
