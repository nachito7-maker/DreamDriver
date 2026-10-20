# Informe de auditoría integral — 18 oct 2026

## Alcance y estado

Se continuó la auditoría del coche y de sus contactos/barreras sobre el estado de trabajo existente. **No se modificó código de producción**: los fallos de suspensión relevantes siguen reproducibles y no hay una reparación justificada aún. La respuesta inequívoca sobre barreras es positiva: cuatro impactos (dos lados, objetivos 36 y 79 km/h) chocaron con la misma malla `WALL` que detectó el rayo; 4/4 frenaron el coche, no hubo paso al otro lado y la penetración permaneció por debajo de 0,5 m. En las escapatorias, 19 maniobras no se detuvieron contra bordes invisibles ni superficies desconocidas; 10 alcanzaron 50 m antes de un muro real, y las tres rutas abiertas superaron 15 m.

## Pruebas controladas del estado actual

- `suspension_probe.gd` repetida en backend headless y render nativo: **FALLA, 9 criterios**. Aceleración produce signos y transferencia que contradicen algunas exigencias; frenada delantera 1,57 mm vs trasera 9,92 mm; transferencias en curva izquierda -5,12 mm y derecha +3,09 mm con aceleración lateral -15,34 m/s² (signo inesperado según el test); el criterio estructural reporta -316,96 mm. El desplazamiento geométrico medido bajo el neumático es mucho menor (peor -1,2 mm), así que la llamada «garantía estructural» usa un marco de coordenadas distinto y no prueba por sí sola penetración física. No se cambia el solver sobre esta base: requiere reconciliar marcos y signos en el fixture/sonda antes de concluir la causa.
- Probe de aislación de `WheelSuspension`: +4 m/s² lateral entrega desplazamientos de signo opuesto al lado de compresión que se espera (roll relativo -0,131°); +4 m/s² longitudinal da frente -1,015 mm, atrás +1,171 mm y pitch +0,036°. Esta prueba reducida no lleva pista ni modelo; demuestra una discrepancia de convención en el signo del balanceo, no un defecto general de colisión.
- Ruedas Red Bull: el JSON montado reporta cuatro contactos, pivotes y órbitas en 0, separación fondo/asfalto entre -3,9 y -5,7 mm. La sonda declara `passed=true`, pero lanza errores de textura nula al intentar guardar capturas con el renderer dummy. La corrida de auditoría copiada para RB22 repite esos errores y el wrapper usado había copiado la sonda a una ruta inexistente; es una ejecución inválida, no resultado del RB22.
- Recta: 313,5 km/h sin detenerse sobre la calzada; se desvía y acaba en arena fuera de pista (control sin dirección). Al acelerar allí avanza 2,677 m en 3 s. Esto no es prueba de pérdida de contacto en recta.
- Impactos y movilidad: PASS según cifras de arriba. Relieve: PASS; 4 grupos de irregularidad se bajan exactamente 1,50 m, muros/superficies restantes inmóviles, 8.722 caras revisadas, ninguna sobresale más de 5 cm.
- Selección: PASS para las 6 combinaciones Barcelona/Suzuka × Red Bull/McLaren/RB22 y menú.
- Carcasa/cámara: la composición del morro pasa la auditoría de píxeles en seis casos, pero `camera_nose_probe` headless da errores de captura (texture null), por lo que esa pasada solo valida los datos/capturas anteriores y no es nueva evidencia visual.

## `verify.sh` completo con límites declarados

Se ejecutó `SKIP_LONG=1 SKIP_HOST=1 SERIAL=emulator-5556 ./verify.sh`. Export y firma del APK, auditorías de materiales/entrega/ruedas, wheel probe, controles host, vuelta, inventario, superficies fuera de pista, dirección, sentido, subviraje, movilidad, impacto, relieve, recta, replay, instalación, arranque limpio, rotación/pantalla, cronómetro y línea de ayuda pasaron donde se indica en `checks.tsv`. El resultado integral terminó **FALLO**, no se presenta como una pasada completa.

Fallos obligatorios del harness: suspensión; auditoría de silueta de persecución; auditoría de línea en píxeles (21/24 subchecks pasan; 3 fallan); huella del APK instalado (hash compilado `7ca114…08ff`, extraído `0931aa…ca90`); lienzo táctil (2424×1080 muestra 24 columnas negras y anclaje de mando fuera por 11 px); multitouch (solo 1 frame simultáneo en el vídeo de 0,393 fps); mando real (relación aplicado/tope 0,50); cámara por píxeles (el inyector no elevó velocidad, todas las capturas quedaron en 0 km/h); y botón-morro en dispositivo (la secuencia terminó con el coche parado y sin avance del cronómetro). Estos resultados son reales del emulador en esta ejecución, pero varias métricas se contaminan por captura/inyección lenta y tienen señales claras de configuración: emulador 2424×1080 con contenido esperado 2400×1080, 24 px de bandas y vídeo touch a 0,393 fps. No se reinterpretan como fallas de física del coche.

Omitidas explícitamente: vuelta completa (`SKIP_LONG=1`) y medición FPS de GPU anfitriona (`SKIP_HOST=1`). La prueba opcional de causalidad `sonda_recto_causa` también falló, sin volver obligatoria la observación del relieve original.

## APK Android: compilación, instalación y divergencia de firma

`verify.sh` exportó/firmó el APK BarcelonaMoto y `adb install -r --no-incremental` devolvió `Success`; el juego arrancó, declaró Barcelona Moto, dibujó HUD y pasó el registro limpio. Sin embargo `huella_instalada` falla: los APK no son byte-a-byte iguales. Tamaño compilado: 577.539.417 bytes; extraído desde el emulador: 230.238.270 bytes. SHA-256 compilado `7ca11448404b591d007311f834d3769dfb2c8ff695fa6cbbe02e60bffe8108ff`; instalado `0931aaeb04d647020e687868f6ecf25b489e0a702fb8bb1c357483b2223ca90f`. Un APK comprimido en almacenamiento reporta un tamaño menor que su origen, pero no iguala el SHA; por tanto no se afirma identidad del artefacto instalado.

El APK RB22 preexistente en `build/android/F1OneShot-RB22-2026.apk` verificó firma apksigner v2/v3, pero no se instaló en este ciclo. Su SHA-256 es `9cc958ae8f5ce91891a650067bdb247610021c893a8c272edb26ef3c31d8d289`; asset integrado `assets/RB22-2026-Verstappen.glb`: `e24d6688336ec5d3d67de149689d1f18ef98fca265d5846ea0003faf2178f84c`.

## Evidencias y huellas de fuentes

El snapshot previo a pruebas está en `current-before-testing/` y su manifiesto de SHA-256 permite comparar bytes. Los scripts/core que se inspeccionaron mantienen hash idéntico al snapshot: `car_controller.gd` `908e37925d12044447db74ad0855f4bde60eb827dfde43de312d134bebb9fb6d`; `race.gd` `1037d6584d920f715783bd68d1c3961c87d349719409f47e1f48114dbb98c02f`; `wheel_suspension.gd` `fd4c22b8bae4eff192099f51a2e938c53fd14c0b2d7343171ffc06784b2e97d6`. Se añadió únicamente una sonda de signo/convención bajo el directorio de recuperación; ver `probes/suspension-sign-probe.gd` y `logs/suspension-sign-probe.log`.

## Salidas clave

- `logs/verify-final.log`, `../integral/checks.tsv` y `../integral/verificacion-integral.json`: ejecución integral y desglose. El resumen final del log indica `resultado: FALLO`; no se generó un archivo `verify-final.exit`.
- `logs/current-retest/suspension-windowed.log`: repetición independiente de suspensión con salida nativa.
- `logs/impact.log`, `logs/mobility.log`, `logs/relief.log`, `logs/straight-redbull.log`, `logs/selection.log` (la selección repetida también está bajo `logs/current-retest/selection.log`).

## Pendientes

1. Rehacer el test de suspensión con una sola convención documentada (eje x, z, yaw, pitch/roll) y expresar despeje estructural en mundo transformando cada contacto; no relajar umbrales antes de ello.
2. Averiguar por qué el supuesto APK extraído no coincide en tamaño/hash, usando el `pm path` activo, `adb pull` y `sha256sum` consecutivos, y hacer la secuencia solo cuando el estado de emulador/montaje pueda sostener la comprobación.
3. Repetir UI/capturas táctiles en lienzo configurado 2400×1080, confirmar primer frame de speed distinto de cero antes de medición y revisar morro a partir de un video con FPS adecuado.
4. Cerrar con test íntegro sin SKIP_LONG/SKIP_HOST y tratar cada salida de captura nula en modo headless como omitida/limitación de ese backend, no como defecto visual.
