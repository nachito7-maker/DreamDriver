# Auditoría del panel negro del cockpit

> Todos los destinos enlazados usan rutas relativas a la raíz del workspace.

**Proyecto:** F1 One Shot Barcelona Moto · **Fecha:** 2026-10-18

## Conclusión

El rectángulo era una pieza **sintética de la cámara**, no una pieza del McLaren ni geometría importada del mod de Assetto Corsa. La generaba `Race._build_onboard_cockpit()` como un `BoxMesh` llamado `Halo front crossbar`, en la ruta `Race/Nose camera/Onboard cockpit details/Halo front crossbar`: tamaño `(0.96, 0.045, 0.055)`, posición local `(0, -0.24, -1.18)`, capa visual 2 y material de carbono casi negro. Su caja ancha y baja cruzaba el parabrisas justo por encima del volante, por eso se leía como una placa negra. La propia sonda de la versión histórica Red Bull encontró exactamente el mismo nodo y dimensiones.

La hipótesis de pieza auténtica queda descartada: el travesaño no coincide con un elemento de ninguno de los dos modelos examinados y era creado directamente en código. Los dos soportes laterales y el pilar central son geometría sintética separada y se conservaron. El nodo no participaba en colisiones ni física. El detalle completo está pegado a la cámara de morro en la capa 2; la cámara exterior usa máscara de render 1, de modo que no dibuja ese conjunto.

## Decisión y cambio

Se **excluyó sólo el travesaño sintético de la representación**, quitando su creación de la función. No se tocó el GLB, los originales del mod, la cámara, materiales de carrocería, colisiones ni sistemas de conducción. No se alteró la geometría real del halo que viene del modelo. El cambio puntual en [race.gd](scripts/race.gd#L972-L980) queda contrastado contra la copia previa [race.gd (respaldo)](.tools/recovery/cockpit-black-20261018/before/race.gd); el único hunk de esta intervención elimina la creación del `BoxMesh` transversal y deja el resto de los detalles intacto.

## Archivos

- **Código de producción modificado:** [scripts/race.gd](scripts/race.gd#L972-L980), sólo el bloque que generaba el travesaño.
- **Respaldo recuperable:** [race.gd antes del cambio](.tools/recovery/cockpit-black-20261018/before/race.gd).
- **Informe:** [INFORME-AUDITORIA.md](.tools/recovery/cockpit-black-20261018/INFORME-AUDITORIA.md).
- **Evidencia y sondas:** capturas PNG enlazadas abajo, [sonda McLaren](.tools/recovery/cockpit-black-20261018/camera-nose-probe.log), [sonda exterior](.tools/recovery/cockpit-black-20261018/camera-exterior-probe.log), [sonda Red Bull legado](.tools/recovery/cockpit-black-20261018/redbull-legacy-probe-final.log), [inspección final](.tools/recovery/cockpit-black-20261018/inspect-visual-final.log).

No se modificaron los recursos importados del vehículo, el circuito, física, conducción, HUD ni controles.

## Evidencia visual

Capturas Godot de 1280×576. La hoja comparativa incluye vistas de morro y exterior del McLaren, morro antes/después del Red Bull legado y la vista exterior del Red Bull tras la eliminación aislada:

- [Antes: morro McLaren](.tools/recovery/cockpit-black-20261018/before/morro-mismo-plano.png)
- [Después: morro McLaren](.tools/recovery/cockpit-black-20261018/after/morro-sin-barra.png)
- [Exterior tras la corrección](.tools/recovery/cockpit-black-20261018/after/exterior-sin-barra.png)
- [Antes: morro Red Bull legado](.tools/recovery/cockpit-black-20261018/before/redbull-morro-mismo-plano.png)
- [Después: morro Red Bull legado](.tools/recovery/cockpit-black-20261018/after/redbull-morro-sin-barra.png)
- [Exterior Red Bull legado](.tools/recovery/cockpit-black-20261018/after/redbull-exterior-sin-barra.png)
- [Hoja comparativa](.tools/recovery/cockpit-black-20261018/comparison-preview.jpg)

La toma posterior del McLaren ya no contiene `Halo front crossbar`; el halo lateral, el poste central, cockpit, volante y display siguen presentes. En el Red Bull legado, la sonda apagó sólo ese nodo y capturó el antes/después con la misma cámara; después cambió a exterior y capturó el coche conservado. La visibilidad externa del elemento estaba limitada a la máscara de cámara de morro.

## Validación

- La inspección del estado final cargó la escena de carrera y reportó `SUSPECT_PATH=ABSENT_AFTER_FIX` y `PRODUCTION_HAS_SUSPECT=false`; guardó de nuevo ambas vistas en [inspect-visual-final.log](.tools/recovery/cockpit-black-20261018/inspect-visual-final.log).
- La sonda de cámara de morro registró seis escenarios, dos transiciones, `errores=0`, `passed=true` en [camera-nose-probe.log](.tools/recovery/cockpit-black-20261018/camera-nose-probe.log).
- La comprobación de cámara exterior recorrió velocidades, frenada y barrido de muros; terminó con `errores=0` en [camera-exterior-probe.log](.tools/recovery/cockpit-black-20261018/camera-exterior-probe.log).
- La prueba del Red Bull legado verificó la ruta exacta, desactivó la pieza y generó ambas capturas en [redbull-legacy-probe-final.log](.tools/recovery/cockpit-black-20261018/redbull-legacy-probe-final.log).
- El diff contra el respaldo de `race.gd` muestra sólo la eliminación del travesaño. Ninguna propiedad de física, conducción, controles o circuito forma parte de ese hunk.

## Limitaciones

Godot en modo `--headless` utiliza el renderer dummy y no permite leer la textura del viewport; la captura por esa vía falló. La comprobación visual se volvió a ejecutar en modo gráfico con OpenGL y terminó correctamente. El Red Bull no está en la escena de producción actual: se probó en la escena de carrera histórica conservada en `visual-20261017/helmet-iteration`, que contiene el modelo y la implementación anteriores, no como selección actual del juego. El primer intento headless no constituye una prueba visual y no se considera aprobado. Un script auxiliar opcional de análisis por píxeles tampoco pudo ejecutarse porque el archivo referido en su ruta no existe; la comparación se hizo con las capturas reales guardadas, y se calculó la diferencia entre PNG mediante Python/Pillow. Ese auxiliar fallido no invalida las sondas gráficas ni las imágenes verificadas.
