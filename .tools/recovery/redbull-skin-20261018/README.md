# Revisión del Red Bull en AC2026/rb.rar

Fecha: 2026-10-18.

## Hallazgo

`AC2026/rb.rar` (RAR v5, 132 MB, 214 entradas) contiene contenido de skins para Assetto Corsa (`rss_formula_hybrid_x_2026` y `rss_formula_hybrid_v12-r`), incluida la carpeta `RB22_3_Verstappen`. La lista íntegra está en `archive-list.txt`. No contiene modelos de vehículo `.kn5`, `.fbx`, `.obj`, `.glb`, `.gltf`, `.blend` o `.dae`; por tanto no proporciona un coche que pueda sustituir al actual. El Red Bull activo que referencia `assets/RedBull.tscn` es `assets/RedBull-Drive.glb`.

## Skin: compatibilidad no aprobada

La textura `2026_Chassis_P.dds` se extrae desde el RAR y su SHA-256 coincide con la copia de trabajo ya examinada. El atlas fue aplicado sólo en una prueba temporal de Blender a la UV del Red Bull activo: el render muestra fragmentos de logotipos/textura repartidos y repetidos, no una librea alineada con la carrocería. La comprobación de UV concluye que la correspondencia de esta textura RSS no queda demostrada y la comparación visual evidencia un mapeo incompatible. No se reemplazó el GLB ni sus imágenes de producción, ni se asignó el atlas a `assets/RedBull.tscn`.

## Evidencia

- `skin-compatibility-comparison.jpg`: baseline y prueba previa de atlas sobre el coche activo.
- `source_uv_0_0_mesh.png`: distribución UV del GLB fuente (sólo diagnóstico).
- `source-uv-skin-probe-zoom.png`: render ampliado de la prueba del atlas DDS sobre la UV actual; resultado desalineado.
- `uv-source-probe.log`, `source-uv-skin-probe-zoom.log`: inspección y render.
- `archive-list.txt`: contenido listado desde el archivo.
- La skin extraída permanece como fuente intacta en `source/`; no fue copiada a producción.

## Resultado

No se realizaron cambios en recursos activos: el archivo suministra una textura de skin para el modelo RSS de Assetto Corsa, no el modelo pedido, y sus UV no coinciden visualmente con el Red Bull activo. Evito así dejar una sustitución incompleta o romper el coche existente. Para completar lo solicitado hace falta el modelo asociado a esta skin o una textura hecha para las UV de `RedBull-Drive.glb`.
